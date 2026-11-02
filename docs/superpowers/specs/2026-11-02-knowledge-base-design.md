# 知识库设计与实现规格

- 日期：2026-11-02
- 状态：待评审
- 涉及仓库：`autoclip-server`（服务端）、`autoclip-web-admin`（管理端）、`huji`（App 端）

## 1. 背景与目标

在弧迹 App 内新增知识库入口，用户可浏览乒乓球/羽毛球技术知识，查看配套的图片与视频。

访问策略：**当前对所有用户开放，后续演进为部分免费、部分订阅专享**。设计必须在今天不为未来挖坑。

目标：

1. 用户能在 App 内浏览知识分类树、知识列表、知识详情及配套图片/视频。
2. 素材托管在现有 MinIO 上，播放走 MinIO 直连（支持 Range），不经 Java 服务转发。
3. 访问级别在知识点与单个素材两个层级都可配置，支持"免费试看 + 订阅解锁剩余"。
4. 未来开启订阅限制，只需调整配置，不改存储结构、不改接口结构、不迁移历史 URL。

## 2. 现状盘点

已有但未被使用的能力：

| 资产 | 位置 | 状态 |
|---|---|---|
| `tech_knowledge` / `tech_videos` / `tech_tags` / `tech_knowledge_relation` / `tech_categories` 表 | `sql/mysql/autoclip-core.sql` | 已建表，`tech_videos` 无种子数据 |
| 后台 CRUD 接口 `/autoclip/tech-knowledge`、`/autoclip/tech-video`、`/autoclip/knowledge-tag` | `controller/admin/` | 可调用 |
| 后台知识管理页（仅文字） | `autoclip-web-admin/src/views/autoclip/techKnowledge/` | 无图片/视频管理 |
| 权限码 `basic_knowledge`(id=14) / `advanced_knowledge`(id=13) | `FeatureCodeEnum`、`autoclip_permission_feature` 种子 | 已定义，无业务引用 |
| `PermissionFeatureService.getUserFeatureCodes(userId)` | `service/impl/subscription/PermissionFeatureServiceImpl.java:148` | 可用，需登录用户 |
| MinIO S3 客户端与预签名能力（GET/PUT/分片） | `S3FileClient.java:140` | 可用 |
| `tech_videos.file_id` 列 | `autoclip-core.sql:753` | 已存在，但 `TechVideoDO` 未映射 |

缺失：App 端只读接口、App 端页面、素材上传入口、访问级别模型。

## 3. 关键决策

### D1 全部素材私有，按需签发，不使用匿名公开桶

**理由**：公开桶的 URL 一旦外流无法收回。今天是免费内容，明天要改成订阅专享，历史直链仍然可播，订阅保护形同虚设；届时迁移存储和链接格式的成本远高于现在多做一步。

因此"免费"的含义是**签发时不校验权限**，而不是**文件公开可读**。未来开启订阅只改 `KnowledgeAccessService` 一处判断，存储路径、接口契约、数据库结构都不动。

**代价**：列表页需要为每个封面生成预签名 URL。签名是本地 HMAC 计算，不产生网络 IO，可接受。

### D2 访问级别挂在知识点，素材可单独覆盖

```java
enum KnowledgeAccessLevel { FREE, BASIC, ADVANCED }
```

- `tech_knowledge.access_level` 非空，默认 `free`
- `tech_media.access_level` 可空，`NULL` 表示继承所属知识点

这样既支持"整块收费"（只配知识点），也支持"首个视频免费试看"（单个素材配 `free`），不需要为试看单独做一套逻辑。

### D3 用 `tech_media` 取代 `tech_videos`

原表只支持视频，但需求包含图片。`tech_videos` 无种子数据、无管理界面、`TechVideoService` 仅被自身的后台控制器引用，改动成本可控。

新表 `tech_media` 用 `media_type` 区分 `image` / `video`，统一排序、说明、访问级别。保留 `source_url` 列，仅用于迁移存量外链，管理端不再允许新填外链（外链无法做访问控制）。

### D4 未解锁不返回 403，返回 `locked` 标记

详情接口照常返回标题、摘要、要点、标签和封面，仅将受保护素材的直链留空，并给出 `locked=true` 与 `requiredFeature`。App 据此渲染正常的详情页加"订阅解锁"引导，而不是错误页。

只有单独请求素材直链时才返回业务错误码 `KNOWLEDGE_LOCKED`。

### D5 高级订阅包含基础订阅

- `basic` 素材：需要 `basic_knowledge` **或** `advanced_knowledge`
- `advanced` 素材：需要 `advanced_knowledge`

订阅方案的功能由后台按 `feature_ids` 配置，不保证天然包含关系，因此在代码里显式定义包含关系，避免运营配置时踩坑。

## 4. 数据模型

```sql
ALTER TABLE tech_knowledge
    ADD COLUMN cover_file_id BIGINT NULL COMMENT '封面文件ID',
    ADD COLUMN access_level VARCHAR(16) NOT NULL DEFAULT 'free'
        COMMENT '访问级别：free/basic/advanced';

CREATE TABLE tech_media (
    id                 BIGINT PRIMARY KEY AUTO_INCREMENT,
    knowledge_id       INT          NOT NULL COMMENT '所属知识点',
    media_type         VARCHAR(16)  NOT NULL COMMENT 'image/video',
    file_id            BIGINT       NULL COMMENT '文件ID，指向 infra_file',
    source_url         VARCHAR(1000) NULL COMMENT '存量外链，仅迁移使用',
    thumbnail_file_id  BIGINT       NULL COMMENT '视频封面文件ID',
    caption            VARCHAR(255) NULL COMMENT '说明文字',
    duration           INT          NULL COMMENT '视频时长（秒）',
    access_level       VARCHAR(16)  NULL COMMENT 'NULL 表示继承知识点',
    sort               INT          NOT NULL DEFAULT 0,
    status             TINYINT      NOT NULL DEFAULT 1,
    creator            VARCHAR(64)  DEFAULT '',
    create_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater            VARCHAR(64)  DEFAULT '',
    update_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted            BIT(1)       NOT NULL DEFAULT b'0',
    tenant_id          BIGINT       NOT NULL DEFAULT 1,
    INDEX idx_knowledge (knowledge_id),
    INDEX idx_status (status),
    CONSTRAINT fk_tech_media_knowledge FOREIGN KEY (knowledge_id)
        REFERENCES tech_knowledge (id) ON DELETE CASCADE
) COMMENT '知识库素材表';
```

`tech_videos` 保留不删，停止写入；确认迁移完成后再由运维手工清理。

**迁移**：`tech_videos` 现有记录按 `knowledge_id` 搬入 `tech_media`（`media_type='video'`，`source_url=video_url`、`thumbnail` 沿用 `thumbnail_url` 对应的文件或留空）。因表内无数据，脚本只做存在性检查并直接跳过。

## 5. 服务端设计

### 5.1 模块划分

| 单元 | 职责 | 依赖 |
|---|---|---|
| `AppKnowledgeController` | 只读 HTTP 接口，参数校验、组装响应 | `TechKnowledgeService`、`KnowledgeAccessService`、`KnowledgeMediaService`、`FileService` |
| `KnowledgeAccessService` | 判定访问级别与用户权限的交集，唯一权限出口 | `PermissionFeatureService` |
| `KnowledgeMediaService` | 素材 CRUD 与列表读取 | `TechMediaMapper` |
| `FileService.getFileUrl(fileId, duration)` | 按文件 ID 签发预签名 GET URL | `FileMapper`、`FileConfigService` |

`KnowledgeAccessService` 是新增的**唯一**权限判断点，App 接口与管理端预览都调用它，避免规则散落。

### 5.2 接口契约

所有接口位于 `/autoclip/app/knowledge`，除注明外均为 `@PermitAll`，登录与否只影响可见范围。

```
GET /tree?categoryId=
GET /page?categoryId=&keyword=&pageNo=&pageSize=
GET /{id}
GET /media/{mediaId}/url
POST /{id}/view
```

**分类树** `tree` → `[{ id, title, accessLevel, locked, children[] }]`

**列表** `page` → `PageResult<KnowledgeCardVO>`（`mediaCount` 由一次分组统计查询得出，避免 N+1）

```json
{
  "id": 12,
  "title": "正手攻球",
  "summary": "…",
  "difficultyLevel": "beginner",
  "accessLevel": "basic",
  "locked": true,
  "coverUrl": "https://…?X-Amz-…",
  "mediaCount": 4
}
```

**详情** `{id}` → 在卡片字段基础上增加 `description`、`keyPoints`、`commonMistakes`、`practiceTips`、`tags`、`viewCount` 与 `media`：

```json
{
  "media": [
    {
      "id": 31,
      "mediaType": "video",
      "caption": "正手攻球慢动作",
      "duration": 48,
      "thumbnailUrl": "https://…?X-Amz-…",
      "accessLevel": "free",
      "locked": false
    }
  ]
}
```

注意：`media` 中**不含直链**，即使未锁定也一样。播放前必须换一次地址，便于后续按次统计与失效控制。

**素材地址** `media/{mediaId}/url`

```json
{ "url": "https://…?X-Amz-…", "expiresAt": "2026-11-02T14:00:00" }
```

未解锁 → `CommonResult` 返回新增错误码 `KNOWLEDGE_LOCKED`（在 `ErrorCodeConstants` 中按现有分段规则追加），`data` 为空。

**浏览量** `POST {id}/view`，`viewCount + 1`，异步或同步均可，不做防刷。

### 5.3 鉴权流程

```
effectiveLevel = media.accessLevel ?? knowledge.accessLevel
if effectiveLevel == free            -> 放行
codes = userId == null ? ∅ : permissionFeatureService.getUserFeatureCodes(userId)
if effectiveLevel == basic   && (codes ∋ basic_knowledge || codes ∋ advanced_knowledge) -> 放行
if effectiveLevel == advanced && codes ∋ advanced_knowledge -> 放行
else -> 锁定
```

`getUserFeatureCodes` 需要非空 userId，匿名访问时必须先判空，不能直接把 null 传进去。

### 5.4 签发策略

| 对象 | 有效期 | 是否鉴权 |
|---|---|---|
| 知识点封面 `cover_file_id` | 7 天 | 否（列表需要展示） |
| 素材封面 `thumbnail_file_id` | 7 天 | 否（同上） |
| 免费素材原文件 | 7 天 | 否 |
| 订阅素材原文件 | 2 小时 | 是 |

2 小时足够看完一段教学视频，又能在用户退订后较快失效。

`FileService` 新增：

```java
String getFileUrl(Long fileId, Duration expiration);
```

实现为 `fileMapper.selectById` → `fileConfigService.getFileClient(configId)` → `getPresignedObjectUrl(path, expiration, PresignedType.GET)`，取返回值中的签名地址。返回 null 表示文件不存在，调用方按"素材缺失"处理。

**注意**：`FilePresignedUrlRespDTO` 的两个字段命名与语义相反——`uploadUrl` 存的是**签名后的地址**（GET 时即为下载地址），`url` 存的是不带签名的 `domain + path`（`S3FileClient.java:114`）。新增方法不要沿用这个命名，直接返回 `String`。

**不要**复用 `/infra/file/{configId}/get/**`，该接口通过 `IoUtil.readBytes` 一次性读入内存（`S3FileClient.java:102`），大视频会 OOM，且不支持 Range。

## 6. 管理端

1. 知识表单新增"访问级别"下拉（免费/基础/高级）与封面上传。
2. 新增素材管理区：图片/视频上传、说明、排序、单独访问级别（默认"继承知识点"）、视频封面。
3. 上传走后端代理：新增 `POST /autoclip/tech-media/upload`，接收 `MultipartFile`，内部调用 `fileService.createFile` 后返回 `{ fileId, url }`。现有 `/infra/file/upload` 只返回 URL 不返回 fileId，无法满足需要。
4. 存储目录固定为 `auto_clip/knowledge/cover`、`auto_clip/knowledge/image`、`auto_clip/knowledge/video`。
5. MinIO 侧**不设置任何匿名策略**，桶保持私有。

## 7. App 端

| 新增 | 说明 |
|---|---|
| `lib/api/internal/autoclip/knowledge_api.dart` | 五个接口的封装，注册到 `ApiManager` |
| `lib/api/models/autoclip/knowledge_models.dart` | 手写 fromJson，沿用现有风格 |
| `lib/pages/knowledge/` | 入口页（分类树 + 列表）、详情页 |

要点：

- 进入详情页时并行拉详情与素材地址，视频用现有播放器（`video_display_item.dart` 已把 `fileUrl` 映射为 `playUrl`）。
- `CachedNetworkImage` 必须显式传 `cacheKey: 'knowledge_cover_$id'`；`flutter_cache_manager` 用 `getSingleFile(url, key: 'knowledge_media_$mediaId')`。否则预签名 URL 每次变化都会重新下载。
- 锁定素材展示遮罩与"订阅解锁"，点击跳现有订阅页（`lib/pages/plan/`）。
- 未登录用户可浏览免费内容；点击锁定素材时引导登录或订阅，取决于届时产品策略，本次只做订阅引导。

## 8. 错误处理

| 场景 | 行为 |
|---|---|
| 知识点不存在 / 已删除 | `KNOWLEDGE_NOT_EXISTS` |
| 素材不存在或 `status=0` | `MEDIA_NOT_EXISTS` |
| 素材受保护且用户无权 | `KNOWLEDGE_LOCKED` |
| `file_id` 为空但 `source_url` 非空 | 返回 `source_url`，不签发（仅迁移兼容） |
| 签发时文件记录不存在 | 视为素材缺失，返回空 URL 并记 warn 日志 |
| MinIO 不可用 | 接口返回 500，App 展示重试 |

## 9. 测试

服务端：

- `KnowledgeAccessServiceTest`：free / basic / advanced × 匿名 / 无订阅 / 基础订阅 / 高级订阅，共 12 组，重点覆盖"高级订阅能否看基础素材"。
- 素材级覆盖继承：知识点 `basic` + 素材 `free` → 可看；知识点 `free` + 素材 `advanced` → 锁定。
- `AppKnowledgeControllerTest`：锁定素材的 `media` 数组不含直链；`locked` 标记正确。
- `FileService.getFileUrl` 单测（Mockito）验证按 fileId 取到正确 path。

App 端：模型解析单测 + 锁定态渲染 widget 测试。

## 10. 非目标

- 不做知识库的搜索分词、推荐、收藏、评论。
- 不做 CDN 接入；域名与 HTTPS 由运维另行配置，本次只保证 URL 是签名直链、可无缝切换域名。
- 不做素材防盗链（Referer / token 绑定）。
- 不改造订阅体系本身。
- 不删除 `tech_videos` 表。

## 11. 风险

| 风险 | 影响 | 应对 |
|---|---|---|
| MinIO 仍以明文 HTTP + 裸端口对外（frp `17584`） | Android 默认禁止明文流量，播放失败 | 上线前配置 Nginx 反代 + 域名 + HTTPS；临时可用 `network_security_config` 白名单 |
| 签名 endpoint 与客户端访问地址不一致 | 直链 403 | `infra_file_config.endpoint` 与 `domain` 都必须是公网可达地址 |
| 列表页封面每次请求都签名 | CPU 开销 | 签名是本地计算，量级可忽略；若后续压力大再加短时缓存 |
| 存量 `tech_videos` 有数据 | 迁移遗漏 | 迁移脚本先 `SELECT COUNT(*)`，非空则逐条搬迁并人工核对 |
