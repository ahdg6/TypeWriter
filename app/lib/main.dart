import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:stack_trace/stack_trace.dart" as stack_trace;
import "package:typewriter/app_router.dart";

void main() async {
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  runApp(const ProviderScope(child: TypeWriterApp()));
}

class TypeWriterApp extends HookConsumerWidget {
  const TypeWriterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouter);
    return MaterialApp.router(
      title: "TypeWriter",
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      routerDelegate: router.delegate(),
      routeInformationParser: router.defaultRouteParser(),
      shortcuts: WidgetsApp.defaultShortcuts,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness);

    return baseTheme.copyWith(
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(baseTheme.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        fillColor: brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2),
        filled: true,
        hoverColor: Colors.black.withOpacity(0.1),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
        ),
        hintStyle: GoogleFonts.jetBrainsMono(
          color: brightness == Brightness.light ? const Color(0x99000000) : const Color(0x99FFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.redAccent.shade200, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      hoverColor: Colors.black.withOpacity(0.1),
      errorColor: Colors.red,
    );
  }
}
