# 知识库服务端实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `autoclip-server` 中实现知识库的素材模型、订阅访问控制与 App 只读接口，使 App 能按用户权限获取图片/视频的签名直链。

**Architecture:** 所有素材存 MinIO 私有桶，通过 `FileService.getFileUrl(fileId, duration)` 按需签发预签名 URL。权限判定收敛在唯一入口 `KnowledgeAccessService`，知识点与素材两级 `access_level`，素材为空表示继承知识点。App 接口只返回元数据与封面签名地址，素材直链必须单独换一次。

**Tech Stack:** Java 17、Spring Boot 3、MyBatis-Plus（yudao `BaseMapperX`）、JUnit 5 + Mockito、MySQL 8

## Global Constraints

- 仓库根目录：`/home/hhoa/autoclip/autoclip-server`
- 包名前缀：`com.hhoa.autoclip.module.core`
- 访问级别取值固定为字符串 `free` / `basic` / `advanced`
- 素材类型取值固定为 `image` / `video`
- 素材存储目录固定为 `auto_clip/knowledge/cover`、`auto_clip/knowledge/image`、`auto_clip/knowledge/video`
- MinIO 桶保持私有，**不得**添加任何匿名读策略
- 不得使用 `/infra/file/{configId}/get/**` 代理下载（一次性读入内存）
- 预签名有效期：封面 7 天；免费素材 7 天；订阅素材 2 小时
- 权限码：`basic_knowledge` 覆盖 `basic`；`advanced_knowledge` 覆盖 `basic` 与 `advanced`
- 测试使用 JUnit 5 + Mockito（`@ExtendWith(MockitoExtension.class)`），不连真实数据库
- 提交信息格式：`feat(core): <描述>`

---

### Task 1: 数据库迁移

**Files:**
- Create: `sql/mysql/migration/2026-11-02-knowledge-base.sql`
- Modify: `sql/mysql/autoclip-core.sql`（在 `tech_knowledge` 建表语句中同步列定义，保证全量建库与增量迁移一致）

**Interfaces:**
- Produces: 表 `tech_media`（列 `id, knowledge_id, media_type, file_id, source_url, thumbnail_file_id, caption, duration, access_level, sort, status, creator, create_time, updater, update_time, deleted, tenant_id`）；`tech_knowledge` 新列 `cover_file_id`、`access_level`

- [ ] **Step 1: 编写迁移脚本**

```sql
-- 2026-11-02 知识库：素材表与访问级别
ALTER TABLE tech_knowledge
    ADD COLUMN cover_file_id BIGINT NULL COMMENT '封面文件ID' AFTER practice_tips,
    ADD COLUMN access_level VARCHAR(16) NOT NULL DEFAULT 'free'
        COMMENT '访问级别：free-免费 basic-基础订阅 advanced-高级订阅' AFTER cover_file_id;

CREATE TABLE tech_media (
    id                BIGINT PRIMARY KEY AUTO_INCREMENT,
    knowledge_id      INT           NOT NULL COMMENT '所属知识点',
    media_type        VARCHAR(16)   NOT NULL COMMENT 'image/video',
    file_id           BIGINT        NULL COMMENT '文件ID，指向 infra_file',
    source_url        VARCHAR(1000) NULL COMMENT '存量外链，仅迁移使用',
    thumbnail_file_id BIGINT        NULL COMMENT '视频封面文件ID',
    caption           VARCHAR(255)  NULL COMMENT '说明文字',
    duration          INT           NULL COMMENT '视频时长（秒）',
    access_level      VARCHAR(16)   NULL COMMENT 'NULL 表示继承知识点',
    sort              INT           NOT NULL DEFAULT 0,
    status            TINYINT       NOT NULL DEFAULT 1,
    creator           VARCHAR(64)   DEFAULT '',
    create_time       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater           VARCHAR(64)   DEFAULT '',
    update_time       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted           BIT(1)        NOT NULL DEFAULT b'0',
    tenant_id         BIGINT        NOT NULL DEFAULT 1,
    INDEX idx_knowledge (knowledge_id),
    INDEX idx_status (status),
    CONSTRAINT fk_tech_media_knowledge FOREIGN KEY (knowledge_id)
        REFERENCES tech_knowledge (id) ON DELETE CASCADE
) COMMENT '知识库素材表';

-- 存量 tech_videos 若为空则跳过。注意：原表只有 file_id，没有 video_url；
-- thumbnail_url 是 URL 无法映射到 thumbnail_file_id，迁移时留空。
-- 必须过滤软删除行，否则被删除的视频会以 active 状态复活；
-- 去重按 (knowledge_id, file_id) 逐行判断，避免一次部分执行后整体静默跳过。
INSERT INTO tech_media (knowledge_id, media_type, file_id, caption, duration, sort, status, creator, tenant_id)
SELECT v.knowledge_id, 'video', v.file_id, v.title, v.duration, v.sort, v.status, v.creator, v.tenant_id
FROM tech_videos v
WHERE v.deleted = 0
  AND NOT EXISTS (
      SELECT 1 FROM tech_media m
      WHERE m.knowledge_id = v.knowledge_id
        AND m.media_type = 'video'
        AND m.file_id <=> v.file_id
  );
```

- [ ] **Step 2: 静态校验迁移脚本**

当前开发机没有 MySQL 服务（`mysql` 客户端未安装、3306 无监听），因此本步只做静态一致性校验，真实执行留到部署环节由人工完成。

Run:
```bash
grep -n "access_level\|cover_file_id" sql/mysql/migration/2026-11-02-knowledge-base.sql
grep -n "access_level\|cover_file_id" sql/mysql/autoclip-core.sql
grep -c "CREATE TABLE IF NOT EXISTS tech_media" sql/mysql/migration/2026-11-02-knowledge-base.sql
```
Expected: 两份文件中都能查到 `access_level` 与 `cover_file_id`；最后一条输出 `1`。同时人工核对 `tech_media` 的 17 个字段与 DO 字段一一对应。

- [ ] **Step 3: 同步全量建库脚本**

在 `sql/mysql/autoclip-core.sql` 的 `tech_knowledge` 建表语句里，`practice_tips` 之后加入同样两列；在 `tech_videos` 建表语句之后加入 `tech_media` 建表语句（内容同 Step 1）。

- [ ] **Step 4: Commit**

```bash
git add sql/mysql/migration/2026-11-02-knowledge-base.sql sql/mysql/autoclip-core.sql
git commit -m "feat(core): add tech_media table and knowledge access level"
```

---

### Task 2: 访问级别枚举与错误码

**Files:**
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/KnowledgeAccessLevelEnum.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/TechMediaTypeEnum.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/ErrorCodeConstants.java`
- Test: `autoclip-core/src/test/java/com/hhoa/autoclip/module/core/enums/KnowledgeAccessLevelEnumTest.java`

**Interfaces:**
- Produces:
  - `KnowledgeAccessLevelEnum.parse(String): KnowledgeAccessLevelEnum`（空值或未知返回 `null`）
  - `KnowledgeAccessLevelEnum.getLevel(): String`、`isFree(): boolean`
  - `TechMediaTypeEnum.IMAGE / VIDEO`，`getType(): String`
  - `ErrorCodeConstants.TECH_MEDIA_NOT_EXISTS`、`KNOWLEDGE_LOCKED`

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.core.enums;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class KnowledgeAccessLevelEnumTest {

    @Test
    void parse_blank_returnsNull() {
        assertNull(KnowledgeAccessLevelEnum.parse(null));
        assertNull(KnowledgeAccessLevelEnum.parse(""));
        assertNull(KnowledgeAccessLevelEnum.parse("   "));
    }

    @Test
    void parse_unknown_returnsNull() {
        assertNull(KnowledgeAccessLevelEnum.parse("vip"));
    }

    @Test
    void parse_known_isCaseInsensitive() {
        assertEquals(KnowledgeAccessLevelEnum.BASIC, KnowledgeAccessLevelEnum.parse("BASIC"));
        assertEquals(KnowledgeAccessLevelEnum.ADVANCED, KnowledgeAccessLevelEnum.parse("advanced"));
    }

    @Test
    void isFree_onlyForFree() {
        assertTrue(KnowledgeAccessLevelEnum.FREE.isFree());
        assertFalse(KnowledgeAccessLevelEnum.BASIC.isFree());
        assertFalse(KnowledgeAccessLevelEnum.ADVANCED.isFree());
    }
}
```

- [ ] **Step 2: 运行测试确认编译失败**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeAccessLevelEnumTest`
Expected: compile error，`KnowledgeAccessLevelEnum` 不存在

- [ ] **Step 3: 实现枚举与错误码**

```java
package com.hhoa.autoclip.module.core.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** 知识库访问级别 */
@Getter
@AllArgsConstructor
public enum KnowledgeAccessLevelEnum {
    FREE("free", "免费"),
    BASIC("basic", "基础订阅"),
    ADVANCED("advanced", "高级订阅");

    private final String level;
    private final String label;

    /** 解析访问级别，空值或未知值返回 null，由调用方决定默认值 */
    public static KnowledgeAccessLevelEnum parse(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        for (KnowledgeAccessLevelEnum item : values()) {
            if (item.level.equalsIgnoreCase(value.trim())) {
                return item;
            }
        }
        return null;
    }

    public boolean isFree() {
        return this == FREE;
    }
}
```

```java
package com.hhoa.autoclip.module.core.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** 知识库素材类型 */
@Getter
@AllArgsConstructor
public enum TechMediaTypeEnum {
    IMAGE("image", "图片"),
    VIDEO("video", "视频");

    private final String type;
    private final String label;
}
```

在 `ErrorCodeConstants` 末尾 `APPLICATION_HAS_RELEASES` 之后追加：

```java
    // 知识库素材相关错误码
    ErrorCode TECH_MEDIA_NOT_EXISTS = new ErrorCode(1_000_012_001, "知识库素材不存在");
    ErrorCode KNOWLEDGE_LOCKED = new ErrorCode(1_000_012_002, "该内容需要订阅后查看");
```

- [ ] **Step 4: 运行测试确认通过**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeAccessLevelEnumTest`
Expected: PASS，4 个用例全绿

- [ ] **Step 5: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/KnowledgeAccessLevelEnum.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/TechMediaTypeEnum.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/enums/ErrorCodeConstants.java \
        autoclip-core/src/test/java/com/hhoa/autoclip/module/core/enums/KnowledgeAccessLevelEnumTest.java
git commit -m "feat(core): add knowledge access level enum and error codes"
```

---

### Task 3: 素材数据模型与查询服务

**Files:**
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/dataobject/TechMediaDO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechMediaMapper.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/TechMediaService.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/TechMediaServiceImpl.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/dataobject/TechKnowledgeDO.java`（补 `coverFileId`、`accessLevel`）
- Test: `autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/TechMediaServiceImplTest.java`

**Interfaces:**
- Produces:
  - `TechMediaDO`：`getId()`、`getKnowledgeId()`、`getMediaType()`、`getFileId()`、`getSourceUrl()`、`getThumbnailFileId()`、`getCaption()`、`getDuration()`、`getAccessLevel()`、`getSort()`、`getStatus()`
  - `TechMediaService.getMediaList(Integer knowledgeId): List<TechMediaDO>`
  - `TechMediaService.getMedia(Long id): TechMediaDO`
  - `TechMediaService.getMediaCountMap(Collection<Integer> knowledgeIds): Map<Integer, Long>`

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.core.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechMediaMapper;
import com.hhoa.autoclip.module.core.service.impl.TechMediaServiceImpl;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TechMediaServiceImplTest {

    @Mock private TechMediaMapper techMediaMapper;

    @InjectMocks private TechMediaServiceImpl techMediaService;

    @Test
    void getMediaList_passesThroughMapper() {
        TechMediaDO media = new TechMediaDO();
        media.setId(1L);
        when(techMediaMapper.selectListByKnowledgeId(10)).thenReturn(List.of(media));

        List<TechMediaDO> result = techMediaService.getMediaList(10);

        assertEquals(1, result.size());
        verify(techMediaMapper).selectListByKnowledgeId(10);
    }

    @Test
    void getMediaCountMap_groupsByKnowledgeId() {
        TechMediaDO a1 = new TechMediaDO();
        a1.setKnowledgeId(10);
        TechMediaDO a2 = new TechMediaDO();
        a2.setKnowledgeId(10);
        TechMediaDO b1 = new TechMediaDO();
        b1.setKnowledgeId(20);
        when(techMediaMapper.selectListByKnowledgeIds(List.of(10, 20)))
                .thenReturn(List.of(a1, a2, b1));

        Map<Integer, Long> counts = techMediaService.getMediaCountMap(List.of(10, 20));

        assertEquals(2L, counts.get(10));
        assertEquals(1L, counts.get(20));
    }

    @Test
    void getMediaCountMap_emptyInput_skipsQuery() {
        assertTrue(techMediaService.getMediaCountMap(List.of()).isEmpty());
        verifyNoInteractions(techMediaMapper);
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=TechMediaServiceImplTest`
Expected: compile error，`TechMediaDO` 不存在

- [ ] **Step 3: 实现 DO**

```java
package com.hhoa.autoclip.module.core.dal.dataobject;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.hhoa.autoclip.framework.mybatis.core.dataobject.BaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

/** 知识库素材 */
@TableName("tech_media")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TechMediaDO extends BaseDO {

    @TableId
    private Long id;

    /** 所属知识点 */
    private Integer knowledgeId;

    /** image / video */
    private String mediaType;

    /** infra_file 主键 */
    private Long fileId;

    /** 存量外链，仅迁移使用，不参与访问控制 */
    private String sourceUrl;

    /** 视频封面文件ID */
    private Long thumbnailFileId;

    private String caption;

    private Integer duration;

    /** NULL 表示继承知识点 */
    private String accessLevel;

    private Integer sort;

    private Integer status;
}
```

在 `TechKnowledgeDO` 的 `practiceTips` 之后补两个字段：

```java
    /** 封面文件ID */
    private Long coverFileId;

    /** 访问级别：free/basic/advanced */
    private String accessLevel;
```

- [ ] **Step 4: 实现 Mapper 与 Service**

```java
package com.hhoa.autoclip.module.core.dal.mysql;

import com.hhoa.autoclip.framework.mybatis.core.mapper.BaseMapperX;
import com.hhoa.autoclip.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import java.util.Collection;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TechMediaMapper extends BaseMapperX<TechMediaDO> {

    default List<TechMediaDO> selectListByKnowledgeId(Integer knowledgeId) {
        return selectList(
                new LambdaQueryWrapperX<TechMediaDO>()
                        .eq(TechMediaDO::getKnowledgeId, knowledgeId)
                        .eq(TechMediaDO::getStatus, 1)
                        .orderByAsc(TechMediaDO::getSort)
                        .orderByAsc(TechMediaDO::getId));
    }

    default List<TechMediaDO> selectListByKnowledgeIds(Collection<Integer> knowledgeIds) {
        return selectList(
                new LambdaQueryWrapperX<TechMediaDO>()
                        .in(TechMediaDO::getKnowledgeId, knowledgeIds)
                        .eq(TechMediaDO::getStatus, 1));
    }
}
```

```java
package com.hhoa.autoclip.module.core.service;

import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import java.util.Collection;
import java.util.List;
import java.util.Map;

public interface TechMediaService {

    List<TechMediaDO> getMediaList(Integer knowledgeId);

    TechMediaDO getMedia(Long id);

    /** 批量统计每个知识点的素材数量，避免列表页 N+1 */
    Map<Integer, Long> getMediaCountMap(Collection<Integer> knowledgeIds);
}
```

```java
package com.hhoa.autoclip.module.core.service.impl;

import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechMediaMapper;
import com.hhoa.autoclip.module.core.service.TechMediaService;
import jakarta.annotation.Resource;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class TechMediaServiceImpl implements TechMediaService {

    @Resource private TechMediaMapper techMediaMapper;

    @Override
    public List<TechMediaDO> getMediaList(Integer knowledgeId) {
        return techMediaMapper.selectListByKnowledgeId(knowledgeId);
    }

    @Override
    public TechMediaDO getMedia(Long id) {
        return techMediaMapper.selectById(id);
    }

    @Override
    public Map<Integer, Long> getMediaCountMap(Collection<Integer> knowledgeIds) {
        if (knowledgeIds == null || knowledgeIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return techMediaMapper.selectListByKnowledgeIds(knowledgeIds).stream()
                .collect(Collectors.groupingBy(TechMediaDO::getKnowledgeId, Collectors.counting()));
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=TechMediaServiceImplTest`
Expected: PASS，3 个用例全绿

- [ ] **Step 6: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/dataobject/TechMediaDO.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechMediaMapper.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/TechMediaService.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/TechMediaServiceImpl.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/dataobject/TechKnowledgeDO.java \
        autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/TechMediaServiceImplTest.java
git commit -m "feat(core): add knowledge media model and query service"
```

---

### Task 4: FileService 按文件 ID 签发

**Files:**
- Modify: `autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileService.java`
- Modify: `autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileServiceImpl.java`
- Test: `autoclip-module-infra/src/test/java/com/hhoa/autoclip/module/infra/service/file/FileServicePresignTest.java`

**Interfaces:**
- Produces: `FileService.getFileUrl(Long fileId, Duration expiration): String`（文件不存在返回 `null`）

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.infra.service.file;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.module.infra.dal.dataobject.file.FileDO;
import com.hhoa.autoclip.module.infra.dal.mysql.file.FileMapper;
import com.hhoa.autoclip.module.infra.framework.file.core.client.FileClient;
import com.hhoa.autoclip.module.infra.framework.file.core.client.s3.FilePresignedUrlRespDTO;
import com.hhoa.autoclip.module.infra.framework.file.core.enums.PresignedType;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class FileServicePresignTest {

    @Mock private FileMapper fileMapper;
    @Mock private FileConfigService fileConfigService;
    @Mock private FileClient fileClient;

    @InjectMocks private FileServiceImpl fileService;

    @Test
    void getFileUrl_nullFileId_returnsNull() {
        assertNull(fileService.getFileUrl(null, Duration.ofDays(1)));
        verifyNoInteractions(fileMapper);
    }

    @Test
    void getFileUrl_fileMissing_returnsNull() {
        when(fileMapper.selectById(9L)).thenReturn(null);
        assertNull(fileService.getFileUrl(9L, Duration.ofDays(1)));
    }

    @Test
    void getFileUrl_clientMissing_returnsNull() {
        FileDO file = new FileDO().setConfigId(3L).setPath("auto_clip/knowledge/video/a.mp4");
        when(fileMapper.selectById(9L)).thenReturn(file);
        when(fileConfigService.getFileClient(3L)).thenReturn(null);
        assertNull(fileService.getFileUrl(9L, Duration.ofDays(1)));
    }

    @Test
    void getFileUrl_success_returnsPresignedUrl() {
        FileDO file = new FileDO().setConfigId(3L).setPath("auto_clip/knowledge/video/a.mp4");
        when(fileMapper.selectById(9L)).thenReturn(file);
        when(fileConfigService.getFileClient(3L)).thenReturn(fileClient);
        when(fileClient.getPresignedObjectUrl(
                        eq("auto_clip/knowledge/video/a.mp4"),
                        eq(Duration.ofHours(2)),
                        eq(PresignedType.GET)))
                .thenReturn(new FilePresignedUrlRespDTO("https://signed", "https://raw"));

        assertEquals("https://signed", fileService.getFileUrl(9L, Duration.ofHours(2)));
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-module-infra -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=FileServicePresignTest`
Expected: compile error，`getFileUrl` 不存在

- [ ] **Step 3: 实现**

在 `FileService` 接口追加：

```java
    /**
     * 按文件 ID 生成预签名读取地址
     *
     * @param fileId 文件编号
     * @param expiration 有效期
     * @return 签名地址；文件、配置或客户端不存在时返回 null
     */
    String getFileUrl(Long fileId, Duration expiration);
```

在 `FileServiceImpl` 追加（`fileConfigService`、`fileMapper` 已注入）：

```java
    @Override
    public String getFileUrl(Long fileId, Duration expiration) {
        if (fileId == null) {
            return null;
        }
        FileDO file = fileMapper.selectById(fileId);
        if (file == null) {
            return null;
        }
        FileClient client = fileConfigService.getFileClient(file.getConfigId());
        if (client == null) {
            return null;
        }
        FilePresignedUrlRespDTO dto =
                client.getPresignedObjectUrl(file.getPath(), expiration, PresignedType.GET);
        // 注意：DTO 的 uploadUrl 字段存的才是签名后的地址，url 是不带签名的裸地址
        return dto == null ? null : dto.getUploadUrl();
    }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `mvn -pl autoclip-module-infra -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=FileServicePresignTest`
Expected: PASS，4 个用例全绿

- [ ] **Step 5: Commit**

```bash
git add autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileService.java \
        autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileServiceImpl.java \
        autoclip-module-infra/src/test/java/com/hhoa/autoclip/module/infra/service/file/FileServicePresignTest.java
git commit -m "feat(infra): presign file url by file id"
```

---

### Task 5: 访问控制服务

**Files:**
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/KnowledgeAccessService.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/KnowledgeAccessServiceImpl.java`
- Test: `autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeAccessServiceImplTest.java`

**Interfaces:**
- Consumes: `KnowledgeAccessLevelEnum.parse`、`PermissionFeatureService.getUserFeatureCodes(Long): Set<String>`
- Produces:
  - `KnowledgeAccessService.resolveLevel(String knowledgeLevel, String mediaLevel): KnowledgeAccessLevelEnum`（素材为空则继承知识点，知识点为空则为 `FREE`）
  - `KnowledgeAccessService.canAccess(KnowledgeAccessLevelEnum required, Long userId): boolean`

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.core.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;
import com.hhoa.autoclip.module.core.service.impl.KnowledgeAccessServiceImpl;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class KnowledgeAccessServiceImplTest {

    @Mock private PermissionFeatureService permissionFeatureService;

    @InjectMocks private KnowledgeAccessServiceImpl accessService;

    // ---------- 级别继承 ----------

    @Test
    void resolveLevel_mediaOverridesKnowledge() {
        assertEquals(
                KnowledgeAccessLevelEnum.FREE,
                accessService.resolveLevel("advanced", "free"));
    }

    @Test
    void resolveLevel_mediaBlank_inheritsKnowledge() {
        assertEquals(
                KnowledgeAccessLevelEnum.ADVANCED,
                accessService.resolveLevel("advanced", null));
        assertEquals(
                KnowledgeAccessLevelEnum.BASIC,
                accessService.resolveLevel("basic", ""));
    }

    @Test
    void resolveLevel_knowledgeBlank_defaultsToFree() {
        assertEquals(KnowledgeAccessLevelEnum.FREE, accessService.resolveLevel(null, null));
        assertEquals(KnowledgeAccessLevelEnum.FREE, accessService.resolveLevel("unknown", null));
    }

    // ---------- 权限矩阵 ----------

    @Test
    void canAccess_free_alwaysTrue() throws Exception {
        assertTrue(accessService.canAccess(KnowledgeAccessLevelEnum.FREE, null));
        assertTrue(accessService.canAccess(KnowledgeAccessLevelEnum.FREE, 1L));
        verifyNoInteractions(permissionFeatureService);
    }

    @Test
    void canAccess_paid_anonymous_false() throws Exception {
        assertFalse(accessService.canAccess(KnowledgeAccessLevelEnum.BASIC, null));
        assertFalse(accessService.canAccess(KnowledgeAccessLevelEnum.ADVANCED, null));
        verifyNoInteractions(permissionFeatureService);
    }

    @Test
    void canAccess_basic_withBasicKnowledge_true() throws Exception {
        when(permissionFeatureService.getUserFeatureCodes(1L)).thenReturn(Set.of("basic_knowledge"));
        assertTrue(accessService.canAccess(KnowledgeAccessLevelEnum.BASIC, 1L));
    }

    @Test
    void canAccess_basic_withAdvancedKnowledge_true() throws Exception {
        when(permissionFeatureService.getUserFeatureCodes(1L))
                .thenReturn(Set.of("advanced_knowledge"));
        assertTrue(accessService.canAccess(KnowledgeAccessLevelEnum.BASIC, 1L));
    }

    @Test
    void canAccess_basic_withoutKnowledgeFeature_false() throws Exception {
        when(permissionFeatureService.getUserFeatureCodes(1L)).thenReturn(Set.of("basic_clip"));
        assertFalse(accessService.canAccess(KnowledgeAccessLevelEnum.BASIC, 1L));
    }

    @Test
    void canAccess_advanced_withBasicKnowledge_false() throws Exception {
        when(permissionFeatureService.getUserFeatureCodes(1L)).thenReturn(Set.of("basic_knowledge"));
        assertFalse(accessService.canAccess(KnowledgeAccessLevelEnum.ADVANCED, 1L));
    }

    @Test
    void canAccess_advanced_withAdvancedKnowledge_true() throws Exception {
        when(permissionFeatureService.getUserFeatureCodes(1L))
                .thenReturn(Set.of("advanced_knowledge"));
        assertTrue(accessService.canAccess(KnowledgeAccessLevelEnum.ADVANCED, 1L));
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeAccessServiceImplTest`
Expected: compile error，`KnowledgeAccessServiceImpl` 不存在

- [ ] **Step 3: 实现**

```java
package com.hhoa.autoclip.module.core.service;

import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;

/** 知识库访问控制，全项目唯一的权限判定入口 */
public interface KnowledgeAccessService {

    /**
     * 计算素材的实际访问级别：素材非空则覆盖，否则继承知识点；知识点为空按 free 处理。
     */
    KnowledgeAccessLevelEnum resolveLevel(String knowledgeLevel, String mediaLevel);

    /**
     * 判断用户是否有权访问该级别内容。匿名用户（userId 为 null）只能访问 free。
     */
    boolean canAccess(KnowledgeAccessLevelEnum required, Long userId) throws Exception;
}
```

```java
package com.hhoa.autoclip.module.core.service.impl;

import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;
import com.hhoa.autoclip.module.core.service.KnowledgeAccessService;
import com.hhoa.autoclip.module.core.service.PermissionFeatureService;
import jakarta.annotation.Resource;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class KnowledgeAccessServiceImpl implements KnowledgeAccessService {

    private static final String BASIC_KNOWLEDGE = "basic_knowledge";
    private static final String ADVANCED_KNOWLEDGE = "advanced_knowledge";

    @Resource private PermissionFeatureService permissionFeatureService;

    @Override
    public KnowledgeAccessLevelEnum resolveLevel(String knowledgeLevel, String mediaLevel) {
        KnowledgeAccessLevelEnum fromMedia = KnowledgeAccessLevelEnum.parse(mediaLevel);
        if (fromMedia != null) {
            return fromMedia;
        }
        KnowledgeAccessLevelEnum fromKnowledge = KnowledgeAccessLevelEnum.parse(knowledgeLevel);
        return fromKnowledge != null ? fromKnowledge : KnowledgeAccessLevelEnum.FREE;
    }

    @Override
    public boolean canAccess(KnowledgeAccessLevelEnum required, Long userId) throws Exception {
        if (required == null || required.isFree()) {
            return true;
        }
        if (userId == null) {
            return false;
        }
        Set<String> codes = permissionFeatureService.getUserFeatureCodes(userId);
        if (required == KnowledgeAccessLevelEnum.BASIC) {
            return codes.contains(BASIC_KNOWLEDGE) || codes.contains(ADVANCED_KNOWLEDGE);
        }
        return codes.contains(ADVANCED_KNOWLEDGE);
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeAccessServiceImplTest`
Expected: PASS，10 个用例全绿

- [ ] **Step 5: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/KnowledgeAccessService.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/KnowledgeAccessServiceImpl.java \
        autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeAccessServiceImplTest.java
git commit -m "feat(core): add knowledge access control service"
```

---

### Task 6: App 端响应 VO 与查询服务

**Files:**
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/AppKnowledgePageReqVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeTreeNodeRespVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeCardRespVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeMediaRespVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeDetailRespVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/KnowledgeQueryService.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/KnowledgeQueryServiceImpl.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechKnowledgeMapper.java`
- Test: `autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeQueryServiceImplTest.java`

**Interfaces:**
- Consumes: `TechMediaService.getMediaList`、`getMediaCountMap`、`KnowledgeAccessService.resolveLevel`/`canAccess`、`FileService.getFileUrl`、`TechKnowledgeMapper`
- Produces:
  - `KnowledgeQueryService.getTree(Integer categoryId, Long userId): List<KnowledgeTreeNodeRespVO>`
  - `KnowledgeQueryService.getPage(AppKnowledgePageReqVO reqVO, Long userId): PageResult<KnowledgeCardRespVO>`
  - `KnowledgeQueryService.getDetail(Integer id, Long userId): KnowledgeDetailRespVO`

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.core.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.AppKnowledgePageReqVO;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeCardRespVO;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeDetailRespVO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechKnowledgeDO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechKnowledgeMapper;
import com.hhoa.autoclip.module.core.service.impl.KnowledgeQueryServiceImpl;
import com.hhoa.autoclip.module.infra.service.file.FileService;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class KnowledgeQueryServiceImplTest {

    @Mock private TechKnowledgeMapper techKnowledgeMapper;
    @Mock private TechMediaService techMediaService;
    @Mock private KnowledgeAccessService knowledgeAccessService;
    @Mock private FileService fileService;

    @InjectMocks private KnowledgeQueryServiceImpl queryService;

    private TechKnowledgeDO knowledge(Integer id, String level, Long coverFileId) {
        TechKnowledgeDO item = new TechKnowledgeDO();
        item.setId(id);
        item.setTitle("正手攻球");
        item.setAccessLevel(level);
        item.setCoverFileId(coverFileId);
        item.setStatusCode(1);
        return item;
    }

    @Test
    void getDetail_lockedMedia_hasNoUrlButFlagged() throws Exception {
        TechKnowledgeDO item = knowledge(12, "basic", null);
        when(techKnowledgeMapper.selectById(12)).thenReturn(item);

        TechMediaDO freeMedia = new TechMediaDO();
        freeMedia.setId(31L);
        freeMedia.setMediaType("video");
        freeMedia.setFileId(100L);
        freeMedia.setAccessLevel("free");
        TechMediaDO paidMedia = new TechMediaDO();
        paidMedia.setId(32L);
        paidMedia.setMediaType("image");
        paidMedia.setFileId(101L);
        paidMedia.setAccessLevel(null);
        when(techMediaService.getMediaList(12)).thenReturn(List.of(freeMedia, paidMedia));

        when(knowledgeAccessService.resolveLevel("basic", "free"))
                .thenReturn(com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum.FREE);
        when(knowledgeAccessService.resolveLevel("basic", null))
                .thenReturn(com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum.BASIC);
        when(knowledgeAccessService.canAccess(any(), isNull())).thenAnswer(inv ->
                inv.getArgument(0) == com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum.FREE);

        KnowledgeDetailRespVO detail = queryService.getDetail(12, null);

        assertEquals(2, detail.getMedia().size());
        assertFalse(detail.getMedia().get(0).getLocked());
        assertTrue(detail.getMedia().get(1).getLocked());
        assertEquals("basic_knowledge", detail.getMedia().get(1).getRequiredFeature());
        // 素材列表不含直链
        assertNull(detail.getMedia().get(0).getUrl());
        verify(fileService, never()).getFileUrl(anyLong(), any(Duration.class));
    }

    @Test
    void getDetail_notExists_returnsNull() throws Exception {
        when(techKnowledgeMapper.selectById(99)).thenReturn(null);
        assertNull(queryService.getDetail(99, 1L));
    }

    @Test
    void getPage_signsCoverUrl() throws Exception {
        TechKnowledgeDO item = knowledge(12, "free", 500L);
        com.hhoa.autoclip.framework.common.pojo.PageResult<TechKnowledgeDO> page =
                new com.hhoa.autoclip.framework.common.pojo.PageResult<>(List.of(item), 1L);
        when(techKnowledgeMapper.selectAppPage(any())).thenReturn(page);
        when(techMediaService.getMediaCountMap(List.of(12))).thenReturn(java.util.Map.of(12, 3L));
        when(fileService.getFileUrl(eq(500L), any(Duration.class))).thenReturn("https://cover");

        AppKnowledgePageReqVO reqVO = new AppKnowledgePageReqVO();
        var result = queryService.getPage(reqVO, null);

        assertEquals(1, result.getList().size());
        KnowledgeCardRespVO card = result.getList().get(0);
        assertEquals("https://cover", card.getCoverUrl());
        assertEquals(3L, card.getMediaCount());
        assertFalse(card.getLocked());
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeQueryServiceImplTest`
Expected: compile error，相关 VO 与 Service 不存在

- [ ] **Step 3: 实现 VO**

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import com.hhoa.autoclip.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Schema(description = "用户 App - 知识库分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppKnowledgePageReqVO extends PageParam {

    @Schema(description = "分类编号")
    private Integer categoryId;

    @Schema(description = "标题关键字")
    private String keyword;
}
```

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import lombok.Data;

@Schema(description = "用户 App - 知识库分类树节点")
@Data
public class KnowledgeTreeNodeRespVO {

    private Integer id;
    private String title;
    private String accessLevel;
    private Boolean locked;
    private List<KnowledgeTreeNodeRespVO> children;
}
```

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 App - 知识库列表卡片")
@Data
public class KnowledgeCardRespVO {

    private Integer id;
    private String title;
    private String summary;
    private String difficultyLevel;
    private String accessLevel;
    private Boolean locked;
    private String coverUrl;
    private Long mediaCount;
}
```

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 App - 知识库素材")
@Data
public class KnowledgeMediaRespVO {

    private Long id;
    private String mediaType;
    private String caption;
    private Integer duration;
    private String thumbnailUrl;
    private String accessLevel;
    private Boolean locked;
    /** 解锁所需权限码，未锁定时为 null */
    private String requiredFeature;
    /** 恒为 null：直链必须通过 /media/{id}/url 换取 */
    private String url;
}
```

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "用户 App - 知识库详情")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class KnowledgeDetailRespVO extends KnowledgeCardRespVO {

    private String description;
    private List<String> keyPoints;
    private String commonMistakes;
    private String practiceTips;
    private Integer viewCount;
    private List<String> tags;
    private List<KnowledgeMediaRespVO> media;
}
```

在 `TechKnowledgeMapper` 追加：

```java
    default PageResult<TechKnowledgeDO> selectAppPage(AppKnowledgePageReqVO reqVO) {
        return selectPage(
                reqVO,
                new LambdaQueryWrapperX<TechKnowledgeDO>()
                        .eqIfPresent(TechKnowledgeDO::getCategoryId, reqVO.getCategoryId())
                        .likeIfPresent(TechKnowledgeDO::getTitle, reqVO.getKeyword())
                        .eq(TechKnowledgeDO::getStatusCode, 1)
                        .orderByDesc(TechKnowledgeDO::getSort)
                        .orderByDesc(TechKnowledgeDO::getId));
    }

    default List<TechKnowledgeDO> selectEnabledList(Integer categoryId) {
        return selectList(
                new LambdaQueryWrapperX<TechKnowledgeDO>()
                        .eqIfPresent(TechKnowledgeDO::getCategoryId, categoryId)
                        .eq(TechKnowledgeDO::getStatusCode, 1)
                        .orderByAsc(TechKnowledgeDO::getSortOrder)
                        .orderByAsc(TechKnowledgeDO::getId));
    }
```

- [ ] **Step 4: 实现查询服务**

```java
package com.hhoa.autoclip.module.core.service;

import com.hhoa.autoclip.framework.common.pojo.PageResult;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.AppKnowledgePageReqVO;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeCardRespVO;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeDetailRespVO;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeTreeNodeRespVO;
import java.util.List;

public interface KnowledgeQueryService {

    List<KnowledgeTreeNodeRespVO> getTree(Integer categoryId, Long userId);

    PageResult<KnowledgeCardRespVO> getPage(AppKnowledgePageReqVO reqVO, Long userId);

    /** 知识点不存在或已禁用时返回 null */
    KnowledgeDetailRespVO getDetail(Integer id, Long userId) throws Exception;
}
```

```java
package com.hhoa.autoclip.module.core.service.impl;

import static cn.hutool.json.JSONUtil.toList;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.hhoa.autoclip.framework.common.pojo.PageResult;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.*;
import com.hhoa.autoclip.module.core.dal.dataobject.TechKnowledgeDO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechKnowledgeMapper;
import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;
import com.hhoa.autoclip.module.core.service.*;
import jakarta.annotation.Resource;
import java.time.Duration;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class KnowledgeQueryServiceImpl implements KnowledgeQueryService {

    private static final Duration COVER_EXPIRATION = Duration.ofDays(7);

    @Resource private TechKnowledgeMapper techKnowledgeMapper;
    @Resource private TechMediaService techMediaService;
    @Resource private KnowledgeAccessService knowledgeAccessService;
    @Resource private com.hhoa.autoclip.module.infra.service.file.FileService fileService;

    @Override
    public List<KnowledgeTreeNodeRespVO> getTree(Integer categoryId, Long userId) {
        List<TechKnowledgeDO> all = techKnowledgeMapper.selectEnabledList(categoryId);
        Map<Integer, List<TechKnowledgeDO>> byParent =
                all.stream()
                        .filter(item -> item.getParentKnowledgeId() != null)
                        .collect(Collectors.groupingBy(TechKnowledgeDO::getParentKnowledgeId));
        Map<Integer, KnowledgeTreeNodeRespVO> nodes = new HashMap<>();
        for (TechKnowledgeDO item : all) {
            nodes.put(item.getId(), toNode(item, userId));
        }
        List<KnowledgeTreeNodeRespVO> roots = new ArrayList<>();
        for (TechKnowledgeDO item : all) {
            KnowledgeTreeNodeRespVO node = nodes.get(item.getId());
            List<TechKnowledgeDO> children = byParent.getOrDefault(item.getId(), List.of());
            node.setChildren(children.stream().map(c -> nodes.get(c.getId())).collect(Collectors.toList()));
            if (item.getParentKnowledgeId() == null || !nodes.containsKey(item.getParentKnowledgeId())) {
                roots.add(node);
            }
        }
        return roots;
    }

    @Override
    public PageResult<KnowledgeCardRespVO> getPage(AppKnowledgePageReqVO reqVO, Long userId) {
        PageResult<TechKnowledgeDO> page = techKnowledgeMapper.selectAppPage(reqVO);
        if (CollUtil.isEmpty(page.getList())) {
            return PageResult.empty();
        }
        List<Integer> ids = page.getList().stream().map(TechKnowledgeDO::getId).collect(Collectors.toList());
        Map<Integer, Long> counts = techMediaService.getMediaCountMap(ids);
        List<KnowledgeCardRespVO> list =
                page.getList().stream()
                        .map(item -> toCard(item, counts.getOrDefault(item.getId(), 0L), userId))
                        .collect(Collectors.toList());
        return new PageResult<>(list, page.getTotal());
    }

    @Override
    public KnowledgeDetailRespVO getDetail(Integer id, Long userId) throws Exception {
        TechKnowledgeDO item = techKnowledgeMapper.selectById(id);
        if (item == null || !Integer.valueOf(1).equals(item.getStatusCode())) {
            return null;
        }
        List<TechMediaDO> mediaList = techMediaService.getMediaList(id);
        KnowledgeDetailRespVO detail = new KnowledgeDetailRespVO();
        fillCard(detail, item, (long) mediaList.size(), userId);

        detail.setDescription(item.getDescription());
        detail.setCommonMistakes(item.getCommonMistakes());
        detail.setPracticeTips(item.getPracticeTips());
        detail.setViewCount(item.getViewCount());
        detail.setKeyPoints(StrUtil.isBlank(item.getKeyPoints())
                ? List.of()
                : toList(item.getKeyPoints(), String.class));
        detail.setMedia(mediaList.stream().map(m -> toMedia(m, item, userId)).collect(Collectors.toList()));
        detail.setTags(List.of());
        return detail;
    }

    private KnowledgeTreeNodeRespVO toNode(TechKnowledgeDO item, Long userId) {
        KnowledgeTreeNodeRespVO node = new KnowledgeTreeNodeRespVO();
        node.setId(item.getId());
        node.setTitle(item.getTitle());
        KnowledgeAccessLevelEnum level =
                knowledgeAccessService.resolveLevel(item.getAccessLevel(), null);
        node.setAccessLevel(level.getLevel());
        node.setLocked(!canAccess(level, userId));
        node.setChildren(new ArrayList<>());
        return node;
    }

    private KnowledgeCardRespVO toCard(TechKnowledgeDO item, Long mediaCount, Long userId) {
        KnowledgeCardRespVO card = new KnowledgeCardRespVO();
        fillCard(card, item, mediaCount, userId);
        return card;
    }

    private void fillCard(KnowledgeCardRespVO card, TechKnowledgeDO item, Long mediaCount, Long userId) {
        KnowledgeAccessLevelEnum level =
                knowledgeAccessService.resolveLevel(item.getAccessLevel(), null);
        card.setId(item.getId());
        card.setTitle(item.getTitle());
        card.setSummary(item.getSummary());
        card.setDifficultyLevel(item.getDifficultyLevel());
        card.setAccessLevel(level.getLevel());
        card.setLocked(!canAccess(level, userId));
        card.setMediaCount(mediaCount);
        card.setCoverUrl(fileService.getFileUrl(item.getCoverFileId(), COVER_EXPIRATION));
    }

    private KnowledgeMediaRespVO toMedia(TechMediaDO media, TechKnowledgeDO item, Long userId) {
        KnowledgeAccessLevelEnum level =
                knowledgeAccessService.resolveLevel(item.getAccessLevel(), media.getAccessLevel());
        boolean accessible = canAccess(level, userId);
        KnowledgeMediaRespVO vo = new KnowledgeMediaRespVO();
        vo.setId(media.getId());
        vo.setMediaType(media.getMediaType());
        vo.setCaption(media.getCaption());
        vo.setDuration(media.getDuration());
        vo.setAccessLevel(level.getLevel());
        vo.setLocked(!accessible);
        vo.setRequiredFeature(accessible ? null : level.getLevel() + "_knowledge");
        vo.setThumbnailUrl(fileService.getFileUrl(media.getThumbnailFileId(), COVER_EXPIRATION));
        vo.setUrl(null);
        return vo;
    }

    private boolean canAccess(KnowledgeAccessLevelEnum level, Long userId) {
        try {
            return knowledgeAccessService.canAccess(level, userId);
        } catch (Exception e) {
            return false;
        }
    }
}
```

> 说明：`requiredFeature` 直接由级别拼成 `basic_knowledge` / `advanced_knowledge`，与 `FeatureCodeEnum` 的 code 保持一致。`tags` 本期返回空列表，标签功能在管理端已有，App 展示留待后续。

- [ ] **Step 5: 运行测试确认通过**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeQueryServiceImplTest`
Expected: PASS，3 个用例全绿

- [ ] **Step 6: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/KnowledgeQueryService.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/KnowledgeQueryServiceImpl.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechKnowledgeMapper.java \
        autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeQueryServiceImplTest.java
git commit -m "feat(core): add app knowledge query service"
```

---

### Task 7: App 知识库 Controller

**Files:**
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/AppKnowledgeController.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeMediaUrlRespVO.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechKnowledgeMapper.java`（`incrementViewCount`）
- Test: `autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeMediaUrlTest.java`

**Interfaces:**
- Consumes: `KnowledgeQueryService`、`TechMediaService`、`KnowledgeAccessService`、`FileService.getFileUrl`
- Produces: HTTP 接口 `/autoclip/knowledge/{tree,page,{id},media/{mediaId}/url,{id}/view}`（框架自动加 `/app-api` 前缀，实际对外为 `/app-api/autoclip/knowledge/**`）

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.core.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.framework.common.exception.ServiceException;
import com.hhoa.autoclip.module.core.dal.dataobject.TechKnowledgeDO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechKnowledgeMapper;
import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;
import com.hhoa.autoclip.module.core.service.impl.KnowledgeMediaUrlServiceImpl;
import com.hhoa.autoclip.module.infra.service.file.FileService;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class KnowledgeMediaUrlTest {

    @Mock private TechKnowledgeMapper techKnowledgeMapper;
    @Mock private TechMediaService techMediaService;
    @Mock private KnowledgeAccessService knowledgeAccessService;
    @Mock private FileService fileService;

    @InjectMocks private KnowledgeMediaUrlServiceImpl service;

    private TechMediaDO media(String level) {
        TechMediaDO media = new TechMediaDO();
        media.setId(31L);
        media.setKnowledgeId(12);
        media.setFileId(100L);
        media.setAccessLevel(level);
        media.setStatus(1);
        return media;
    }

    private TechKnowledgeDO knowledge(String level) {
        TechKnowledgeDO item = new TechKnowledgeDO();
        item.setId(12);
        item.setAccessLevel(level);
        item.setStatusCode(1);
        return item;
    }

    @Test
    void getUrl_mediaMissing_throws() {
        when(techMediaService.getMedia(31L)).thenReturn(null);
        assertThrows(ServiceException.class, () -> service.getUrl(31L, 1L));
    }

    @Test
    void getUrl_locked_throws() throws Exception {
        when(techMediaService.getMedia(31L)).thenReturn(media(null));
        when(techKnowledgeMapper.selectById(12)).thenReturn(knowledge("advanced"));
        when(knowledgeAccessService.resolveLevel("advanced", null))
                .thenReturn(KnowledgeAccessLevelEnum.ADVANCED);
        when(knowledgeAccessService.canAccess(KnowledgeAccessLevelEnum.ADVANCED, 1L))
                .thenReturn(false);
        assertThrows(ServiceException.class, () -> service.getUrl(31L, 1L));
    }

    @Test
    void getUrl_free_signedForSevenDays() throws Exception {
        when(techMediaService.getMedia(31L)).thenReturn(media(null));
        when(techKnowledgeMapper.selectById(12)).thenReturn(knowledge("free"));
        when(knowledgeAccessService.resolveLevel("free", null))
                .thenReturn(KnowledgeAccessLevelEnum.FREE);
        when(knowledgeAccessService.canAccess(KnowledgeAccessLevelEnum.FREE, 1L)).thenReturn(true);
        when(fileService.getFileUrl(100L, Duration.ofDays(7))).thenReturn("https://signed-free");

        assertEquals("https://signed-free", service.getUrl(31L, 1L).getUrl());
    }

    @Test
    void getUrl_basic_signedForTwoHours() throws Exception {
        when(techMediaService.getMedia(31L)).thenReturn(media(null));
        when(techKnowledgeMapper.selectById(12)).thenReturn(knowledge("basic"));
        when(knowledgeAccessService.resolveLevel("basic", null))
                .thenReturn(KnowledgeAccessLevelEnum.BASIC);
        when(knowledgeAccessService.canAccess(KnowledgeAccessLevelEnum.BASIC, 1L)).thenReturn(true);
        when(fileService.getFileUrl(100L, Duration.ofHours(2))).thenReturn("https://signed-paid");

        assertEquals("https://signed-paid", service.getUrl(31L, 1L).getUrl());
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeMediaUrlTest`
Expected: compile error，`KnowledgeMediaUrlServiceImpl` 不存在

- [ ] **Step 3: 实现地址服务与 Controller**

```java
package com.hhoa.autoclip.module.core.controller.app.vo.knowledge;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;

@Schema(description = "用户 App - 素材直链")
@Data
@AllArgsConstructor
public class KnowledgeMediaUrlRespVO {

    private String url;
    private LocalDateTime expiresAt;
}
```

```java
package com.hhoa.autoclip.module.core.service;

import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeMediaUrlRespVO;

public interface KnowledgeMediaUrlService {

    /** 校验通过后签发直链；素材不存在或无权访问时抛 ServiceException */
    KnowledgeMediaUrlRespVO getUrl(Long mediaId, Long userId) throws Exception;
}
```

```java
package com.hhoa.autoclip.module.core.service.impl;

import static com.hhoa.autoclip.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.hhoa.autoclip.module.core.enums.ErrorCodeConstants.*;

import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.KnowledgeMediaUrlRespVO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechKnowledgeDO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechKnowledgeMapper;
import com.hhoa.autoclip.module.core.enums.KnowledgeAccessLevelEnum;
import com.hhoa.autoclip.module.core.service.KnowledgeAccessService;
import com.hhoa.autoclip.module.core.service.KnowledgeMediaUrlService;
import com.hhoa.autoclip.module.core.service.TechMediaService;
import com.hhoa.autoclip.module.infra.service.file.FileService;
import jakarta.annotation.Resource;
import java.time.Duration;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;

@Service
public class KnowledgeMediaUrlServiceImpl implements KnowledgeMediaUrlService {

    private static final Duration FREE_EXPIRATION = Duration.ofDays(7);
    private static final Duration PAID_EXPIRATION = Duration.ofHours(2);

    @Resource private TechMediaService techMediaService;
    @Resource private TechKnowledgeMapper techKnowledgeMapper;
    @Resource private KnowledgeAccessService knowledgeAccessService;
    @Resource private FileService fileService;

    @Override
    public KnowledgeMediaUrlRespVO getUrl(Long mediaId, Long userId) throws Exception {
        TechMediaDO media = techMediaService.getMedia(mediaId);
        if (media == null || !Integer.valueOf(1).equals(media.getStatus())) {
            throw exception(TECH_MEDIA_NOT_EXISTS);
        }
        TechKnowledgeDO knowledge = techKnowledgeMapper.selectById(media.getKnowledgeId());
        if (knowledge == null) {
            throw exception(TECH_KNOWLEDGE_NOT_EXISTS);
        }
        KnowledgeAccessLevelEnum level =
                knowledgeAccessService.resolveLevel(knowledge.getAccessLevel(), media.getAccessLevel());
        if (!knowledgeAccessService.canAccess(level, userId)) {
            throw exception(KNOWLEDGE_LOCKED);
        }
        // 存量外链不参与访问控制，仅在无 fileId 时回退
        if (media.getFileId() == null) {
            return new KnowledgeMediaUrlRespVO(media.getSourceUrl(), LocalDateTime.now().plus(PAID_EXPIRATION));
        }
        Duration expiration = level.isFree() ? FREE_EXPIRATION : PAID_EXPIRATION;
        return new KnowledgeMediaUrlRespVO(
                fileService.getFileUrl(media.getFileId(), expiration),
                LocalDateTime.now().plus(expiration));
    }
}
```

在 `TechKnowledgeMapper` 追加：

```java
    default void incrementViewCount(Integer id) {
        update(null, new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<TechKnowledgeDO>()
                .setSql("view_count = view_count + 1")
                .eq("id", id));
    }
```

```java
package com.hhoa.autoclip.module.core.controller.app;

import static com.hhoa.autoclip.framework.common.pojo.CommonResult.success;
import static com.hhoa.autoclip.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

import com.hhoa.autoclip.framework.common.pojo.CommonResult;
import com.hhoa.autoclip.framework.common.pojo.PageResult;
import com.hhoa.autoclip.module.core.controller.app.vo.knowledge.*;
import com.hhoa.autoclip.module.core.dal.mysql.TechKnowledgeMapper;
import com.hhoa.autoclip.module.core.service.KnowledgeMediaUrlService;
import com.hhoa.autoclip.module.core.service.KnowledgeQueryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.annotation.security.PermitAll;
import jakarta.validation.Valid;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/autoclip/knowledge")
@Tag(name = "用户 App - 知识库")
@Validated
@Slf4j
public class AppKnowledgeController {

    @Resource private KnowledgeQueryService knowledgeQueryService;
    @Resource private KnowledgeMediaUrlService knowledgeMediaUrlService;
    @Resource private TechKnowledgeMapper techKnowledgeMapper;

    @GetMapping("/tree")
    @Operation(summary = "知识库分类树")
    @PermitAll
    public CommonResult<List<KnowledgeTreeNodeRespVO>> getTree(
            @RequestParam(value = "categoryId", required = false) Integer categoryId) {
        return success(knowledgeQueryService.getTree(categoryId, getLoginUserId()));
    }

    @GetMapping("/page")
    @Operation(summary = "知识库分页")
    @PermitAll
    public CommonResult<PageResult<KnowledgeCardRespVO>> getPage(@Valid AppKnowledgePageReqVO reqVO) {
        return success(knowledgeQueryService.getPage(reqVO, getLoginUserId()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "知识库详情")
    @PermitAll
    public CommonResult<KnowledgeDetailRespVO> getDetail(@PathVariable("id") Integer id)
            throws Exception {
        return success(knowledgeQueryService.getDetail(id, getLoginUserId()));
    }

    @GetMapping("/media/{mediaId}/url")
    @Operation(summary = "换取素材直链")
    @PermitAll
    public CommonResult<KnowledgeMediaUrlRespVO> getMediaUrl(@PathVariable("mediaId") Long mediaId)
            throws Exception {
        return success(knowledgeMediaUrlService.getUrl(mediaId, getLoginUserId()));
    }

    @PostMapping("/{id}/view")
    @Operation(summary = "浏览计数")
    @PermitAll
    public CommonResult<Boolean> addView(@PathVariable("id") Integer id) {
        techKnowledgeMapper.incrementViewCount(id);
        return success(true);
    }
}
```

> **注意**：`@PermitAll` 必须标在方法上。`AutoclipWebSecurityConfigurerAdapter:198` 用的是 `handlerMethod.hasMethodAnnotation(PermitAll.class)`，类级注解不会生效。

- [ ] **Step 4: 运行测试确认通过**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=KnowledgeMediaUrlTest`
Expected: PASS，4 个用例全绿

- [ ] **Step 5: 全量编译并跑知识库相关测试**

Run: `mvn -pl autoclip-core -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest='Knowledge*Test,TechMediaServiceImplTest'`
Expected: 全部 PASS

- [ ] **Step 6: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/AppKnowledgeController.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/app/vo/knowledge/KnowledgeMediaUrlRespVO.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/KnowledgeMediaUrlService.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/service/impl/KnowledgeMediaUrlServiceImpl.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/mysql/TechKnowledgeMapper.java \
        autoclip-core/src/test/java/com/hhoa/autoclip/module/core/service/KnowledgeMediaUrlTest.java
git commit -m "feat(core): expose app knowledge endpoints"
```

---

### Task 8: 管理端上传接口与素材 CRUD

**Files:**
- Modify: `autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileService.java`
- Modify: `autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileServiceImpl.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/AdminTechMediaController.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechMediaSaveReqVO.java`
- Create: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechMediaUploadRespVO.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/dal/dataobject/TechMediaDO.java`（无需改动，已在 Task 3 定义）
- Test: `autoclip-module-infra/src/test/java/com/hhoa/autoclip/module/infra/service/file/FileServiceCreateTest.java`

**Interfaces:**
- Consumes: `FileService.createFile`、`TechMediaMapper`
- Produces:
  - `FileService.createFileAndGetFile(byte[], String, String, String): FileDO`
  - `POST /autoclip/tech-media/upload` → `{ fileId, url }`
  - `POST /autoclip/tech-media/create`、`PUT /autoclip/tech-media/update`、`DELETE /autoclip/tech-media/delete`、`GET /autoclip/tech-media/list?knowledgeId=`

- [ ] **Step 1: 写失败测试**

```java
package com.hhoa.autoclip.module.infra.service.file;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.hhoa.autoclip.module.infra.dal.dataobject.file.FileDO;
import com.hhoa.autoclip.module.infra.dal.mysql.file.FileMapper;
import com.hhoa.autoclip.module.infra.framework.file.core.client.FileClient;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class FileServiceCreateTest {

    @Mock private FileMapper fileMapper;
    @Mock private FileConfigService fileConfigService;
    @Mock private FileClient fileClient;

    @InjectMocks private FileServiceImpl fileService;

    @Test
    void createFileAndGetFile_returnsPersistedRecord() {
        when(fileConfigService.getMasterFileClient()).thenReturn(fileClient);
        when(fileClient.getId()).thenReturn(3L);
        when(fileClient.upload(any(byte[].class), any(String.class), any(String.class)))
                .thenReturn("https://raw/a.mp4");
        when(fileMapper.insert(any(FileDO.class))).thenAnswer(inv -> {
            ((FileDO) inv.getArgument(0)).setId(88L);
            return 1;
        });

        FileDO file = fileService.createFileAndGetFile(
                new byte[] {1, 2, 3}, "a.mp4", "auto_clip/knowledge/video", "video/mp4");

        assertEquals(88L, file.getId());
        assertEquals(3L, file.getConfigId());
        assertEquals("https://raw/a.mp4", file.getUrl());
        assertTrue(file.getPath().startsWith("auto_clip/knowledge/video/"));
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `mvn -pl autoclip-module-infra -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=FileServiceCreateTest`
Expected: compile error，`createFileAndGetFile` 不存在

- [ ] **Step 3: 重构 FileServiceImpl**

在 `FileService` 接口追加：

```java
    /**
     * 保存文件并返回完整的文件记录（含自增主键），供需要 fileId 的调用方使用
     */
    FileDO createFileAndGetFile(byte[] content, String name, String directory, String type);
```

在 `FileServiceImpl` 中把现有 `createFile` 的主体抽到新方法，`createFile` 改为委托：

```java
    @Override
    public String createFile(byte[] content, String name, String directory, String type) {
        return createFileAndGetFile(content, name, directory, type).getUrl();
    }

    @Override
    @SneakyThrows
    public FileDO createFileAndGetFile(byte[] content, String name, String directory, String type) {
        // 1.1 处理 type 为空的情况
        if (StrUtil.isEmpty(type)) {
            type = FileTypeUtils.getMineType(content, name);
        }
        // 1.2 处理 name 为空的情况
        if (StrUtil.isEmpty(name)) {
            name = DigestUtil.sha256Hex(content);
        }
        if (StrUtil.isEmpty(FileUtil.extName(name))) {
            String extension = FileTypeUtils.getExtension(type);
            if (StrUtil.isNotEmpty(extension)) {
                name = name + extension;
            }
        }
        // 2.1 生成上传的 path
        String path = generateUploadPath(name, directory, true);
        // 2.2 上传到文件存储器
        FileClient client = fileConfigService.getMasterFileClient();
        Assert.notNull(client, "客户端(master) 不能为空");
        String url = client.upload(content, path, type);
        // 3. 保存到数据库
        FileDO file = new FileDO()
                .setConfigId(client.getId())
                .setName(name)
                .setPath(path)
                .setUrl(url)
                .setType(type)
                .setSize(content.length);
        fileMapper.insert(file);
        return file;
    }
```

注意：`createFile` 上原有的 `@SneakyThrows` 移到新方法即可，行为不变。

- [ ] **Step 4: 实现管理端 Controller**

```java
package com.hhoa.autoclip.module.core.controller.admin.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Schema(description = "管理后台 - 知识库素材保存 Request VO")
@Data
public class AdminTechMediaSaveReqVO {

    @Schema(description = "素材编号，更新时必填")
    private Long id;

    @NotNull(message = "所属知识点不能为空")
    private Integer knowledgeId;

    @NotEmpty(message = "素材类型不能为空")
    private String mediaType;

    private Long fileId;

    private String sourceUrl;

    private Long thumbnailFileId;

    private String caption;

    private Integer duration;

    /** 为空表示继承知识点 */
    private String accessLevel;

    private Integer sort;

    private Integer status;
}
```

```java
package com.hhoa.autoclip.module.core.controller.admin.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;

@Schema(description = "管理后台 - 素材上传结果")
@Data
@AllArgsConstructor
public class AdminTechMediaUploadRespVO {

    private Long fileId;
    private String url;
}
```

```java
package com.hhoa.autoclip.module.core.controller.admin;

import static com.hhoa.autoclip.framework.common.pojo.CommonResult.success;

import cn.hutool.core.io.IoUtil;
import com.hhoa.autoclip.framework.common.pojo.CommonResult;
import com.hhoa.autoclip.module.core.controller.admin.vo.AdminTechMediaSaveReqVO;
import com.hhoa.autoclip.module.core.controller.admin.vo.AdminTechMediaUploadRespVO;
import com.hhoa.autoclip.module.core.dal.dataobject.TechMediaDO;
import com.hhoa.autoclip.module.core.dal.mysql.TechMediaMapper;
import com.hhoa.autoclip.module.core.enums.ErrorCodeConstants;
import com.hhoa.autoclip.module.core.service.TechMediaService;
import com.hhoa.autoclip.module.infra.dal.dataobject.file.FileDO;
import com.hhoa.autoclip.module.infra.service.file.FileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import static com.hhoa.autoclip.framework.common.exception.util.ServiceExceptionUtil.exception;

@RestController
@RequestMapping("/autoclip/tech-media")
@Tag(name = "管理后台 - 知识库素材")
@Validated
@Slf4j
public class AdminTechMediaController {

    private static final Map<String, String> DIRECTORY_BY_TYPE =
            Map.of("image", "auto_clip/knowledge/image", "video", "auto_clip/knowledge/video");

    @Resource private TechMediaService techMediaService;
    @Resource private TechMediaMapper techMediaMapper;
    @Resource private FileService fileService;

    @PostMapping("/upload")
    @Operation(summary = "上传素材文件")
    public CommonResult<AdminTechMediaUploadRespVO> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "mediaType", defaultValue = "video") String mediaType)
            throws Exception {
        String directory = DIRECTORY_BY_TYPE.getOrDefault(mediaType, "auto_clip/knowledge/video");
        FileDO saved =
                fileService.createFileAndGetFile(
                        IoUtil.readBytes(file.getInputStream()),
                        file.getOriginalFilename(),
                        directory,
                        file.getContentType());
        return success(new AdminTechMediaUploadRespVO(saved.getId(), saved.getUrl()));
    }

    @GetMapping("/list")
    @Operation(summary = "素材列表")
    public CommonResult<List<TechMediaDO>> list(@RequestParam("knowledgeId") Integer knowledgeId) {
        return success(techMediaService.getMediaList(knowledgeId));
    }

    @PostMapping("/create")
    @Operation(summary = "创建素材")
    public CommonResult<Long> create(@Valid @RequestBody AdminTechMediaSaveReqVO reqVO) {
        TechMediaDO media = new TechMediaDO();
        copy(reqVO, media);
        techMediaMapper.insert(media);
        return success(media.getId());
    }

    @PutMapping("/update")
    @Operation(summary = "更新素材")
    public CommonResult<Boolean> update(@Valid @RequestBody AdminTechMediaSaveReqVO reqVO) {
        if (reqVO.getId() == null) {
            throw exception(ErrorCodeConstants.TECH_MEDIA_NOT_EXISTS);
        }
        TechMediaDO media = new TechMediaDO();
        copy(reqVO, media);
        media.setId(reqVO.getId());
        techMediaMapper.updateById(media);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除素材")
    public CommonResult<Boolean> delete(@RequestParam("id") Long id) {
        techMediaMapper.deleteById(id);
        return success(true);
    }

    private void copy(AdminTechMediaSaveReqVO reqVO, TechMediaDO media) {
        media.setKnowledgeId(reqVO.getKnowledgeId());
        media.setMediaType(reqVO.getMediaType());
        media.setFileId(reqVO.getFileId());
        media.setSourceUrl(reqVO.getSourceUrl());
        media.setThumbnailFileId(reqVO.getThumbnailFileId());
        media.setCaption(reqVO.getCaption());
        media.setDuration(reqVO.getDuration());
        media.setAccessLevel(reqVO.getAccessLevel());
        media.setSort(reqVO.getSort() == null ? 0 : reqVO.getSort());
        media.setStatus(reqVO.getStatus() == null ? 1 : reqVO.getStatus());
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `mvn -pl autoclip-module-infra -am test -Dsurefire.failIfNoSpecifiedTests=false -Dtest=FileServiceCreateTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileService.java \
        autoclip-module-infra/src/main/java/com/hhoa/autoclip/module/infra/service/file/FileServiceImpl.java \
        autoclip-module-infra/src/test/java/com/hhoa/autoclip/module/infra/service/file/FileServiceCreateTest.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/AdminTechMediaController.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechMediaSaveReqVO.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechMediaUploadRespVO.java
git commit -m "feat(core): add admin knowledge media endpoints"
```

---

### Task 9: 管理端知识 CRUD 支持访问级别与封面

**Files:**
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeCreateReqVO.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeUpdateReqVO.java`
- Modify: `autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeRespVO.java`
- Test: 无新增单测；由 Task 6 的 `getPage`/`getDetail` 用例覆盖读取路径

**Interfaces:**
- Produces: 三个 VO 均新增 `Long coverFileId`、`String accessLevel`

- [ ] **Step 1: 给三个 VO 各加两个字段**

```java
    @Schema(description = "封面文件ID")
    private Long coverFileId;

    @Schema(description = "访问级别：free/basic/advanced", example = "free")
    private String accessLevel;
```

- [ ] **Step 2: 验证 Bean 拷贝链路**

`AdminTechKnowledgeRespVO` 由 `BeanUtils.toBean` 从 `TechKnowledgeDO` 转换，`TechKnowledgeDO` 已在 Task 3 补了同名字段，字段名一致即可自动映射。

Run: `mvn -pl autoclip-core -am compile`
Expected: BUILD SUCCESS

- [ ] **Step 3: 编译验证**

Run: `mvn -pl autoclip-core -am -DskipTests compile`
Expected: BUILD SUCCESS

> 运行时冒烟（启动服务、`/admin-api/autoclip/tech-knowledge/create` 断言 `accessLevel` 生效）需要数据库与 MinIO，当前开发机不具备条件，留到部署环境由人工执行。

- [ ] **Step 4: Commit**

```bash
git add autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeCreateReqVO.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeUpdateReqVO.java \
        autoclip-core/src/main/java/com/hhoa/autoclip/module/core/controller/admin/vo/AdminTechKnowledgeRespVO.java
git commit -m "feat(core): support access level and cover on knowledge admin apis"
```

---

## 后续计划

本计划只覆盖服务端。接口契约已在此固定，后续两份独立计划：

- **管理端**（`autoclip-web-admin`）：知识表单增加访问级别与封面上传；新增素材管理页；接 `/autoclip/tech-media/*`
- **App 端**（`huji`）：`knowledge_api.dart`、模型、列表页/详情页、订阅引导、缓存 key

## Self-Review

**Spec 覆盖检查**

| spec 章节 | 对应任务 |
|---|---|
| §3 D1 私有存储 + 按需签发 | Task 4、Task 7 |
| §3 D2 知识点级 + 素材级覆盖 | Task 5 `resolveLevel` |
| §3 D3 `tech_media` 取代 `tech_videos` | Task 1、Task 3 |
| §3 D4 `locked` 而非 403 | Task 6 `toMedia`、Task 7 错误码 |
| §3 D5 高级包含基础 | Task 5 权限矩阵用例 |
| §4 数据模型 | Task 1、Task 3 |
| §5.1 模块划分 | Task 3–7 |
| §5.2 接口契约 | Task 6、Task 7 |
| §5.3 鉴权流程 | Task 5 |
| §5.4 签发策略 | Task 4、Task 6、Task 7 |
| §6 管理端接口 | Task 8、Task 9 |
| §8 错误处理 | Task 2、Task 7 |
| §9 测试 | 各任务测试步骤 |
| §11 风险 | 未在服务端代码中处理（Nginx/HTTPS 属运维） |

**已知缺口**

- 标签（`tags`）在 `KnowledgeDetailRespVO` 中恒返回空列表；标签数据已在 `knowledge_tags` 表中，App 展示留待后续计划补齐。
- `/autoclip/knowledge/**` 未加入 `application.yaml` 的 `permit-all_urls`，依赖 Controller 上的 `@PermitAll` 放行。若后续去掉类级注解，需要同步配置白名单。
- 本计划不含 Nginx 反代与 HTTPS 配置，见 spec §11 风险。
