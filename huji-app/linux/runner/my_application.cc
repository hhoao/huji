#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <native_splash_screen_linux/native_splash_screen_linux_plugin.h>

#include <limits.h>
#include <unistd.h>
#include <libgen.h>

#include "flutter/generated_plugin_registrant.h"

// Resolve the absolute path of the bundled application icon by walking up from
// the running executable to <bundle>/data/flutter_assets/assets/icons/logo_bg.png.
static gchar* resolve_app_icon_path() {
  char exe_path[PATH_MAX] = {0};
  ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
  if (len <= 0) {
    return nullptr;
  }
  exe_path[len] = '\0';
  gchar* exe_dir = g_path_get_dirname(exe_path);
  gchar* icon_path = g_build_filename(
      exe_dir, "data", "flutter_assets", "assets", "icons", "logo_bg.png",
      nullptr);
  g_free(exe_dir);
  return icon_path;
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Client-side decorations: Flutter + window_manager draw the title bar
  // (see DesktopWindowTitleBar). Starting frameless avoids the visible
  // GtkHeaderBar -> custom title bar swap on every launch.
  gtk_window_set_title(window, "弧迹");
  gtk_window_set_decorated(window, FALSE);

  // Keep in sync with kDefaultDesktopWindowSize in lib/main.dart.
  gtk_window_set_default_size(window, 1280, 800);

  g_autofree gchar* icon_path = resolve_app_icon_path();
  if (icon_path != nullptr && g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    g_autoptr(GError) icon_error = nullptr;
    if (!gtk_window_set_icon_from_file(window, icon_path, &icon_error)) {
      g_warning("Failed to load window icon: %s", icon_error->message);
    }
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));

  // Overlay-mode boot splash: stack the splash bitmap over the Flutter view in
  // THIS window (instead of a separate top-level splash window), so it paints
  // background+logo from the first map and Dart fades it out via close() once
  // the app has painted. Avoids the second-top-level decoration/alignment
  // artifacts on GNOME/Wayland. This replaces adding the view to the window
  // directly.
  native_splash_screen_attach_overlay(window, view);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));

  // Default to the dark scaffold tone (kDefaultBootSplashColor); the window CSS
  // only shows through before the first Flutter paint, which the splash
  // overlay already covers.
  GtkCssProvider* css_provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      css_provider, "window { background-color: #15181C; }", -1, nullptr);
  GtkStyleContext* style_context = gtk_widget_get_style_context(GTK_WIDGET(window));
  gtk_style_context_add_provider(
      style_context, GTK_STYLE_PROVIDER(css_provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(css_provider);

  // The widget tree (including the splash overlay) is built, so the first paint
  // already shows the splash.
  gtk_widget_show(GTK_WIDGET(window));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
