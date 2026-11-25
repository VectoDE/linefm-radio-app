import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'context.dart';
import 'controller.dart';
import 'engine.dart';
import 'strings.dart';
import 'theme.dart';

/// Wurzel der Setup-Oberfläche. Sprache und Hell/Dunkel folgen Windows.
class SetupApp extends StatefulWidget {
  const SetupApp({
    super.key,
    required this.controller,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final SetupController controller;

  /// Fest vorgegebene Sprache (Tests); sonst die von Windows.
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  State<SetupApp> createState() => _SetupAppState();
}

class _SetupAppState extends State<SetupApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _close;

  @override
  void initState() {
    super.initState();
    _close = widget.controller.platform.closeRequests.listen(
      (_) => unawaited(_onCloseRequested()),
    );
  }

  @override
  void dispose() {
    unawaited(_close?.cancel());
    super.dispose();
  }

  Future<void> _onCloseRequested() async {
    final c = widget.controller;
    final ctx = _navigator.currentContext;
    if (ctx == null) return;
    if (c.step == SetupStep.done) {
      c.exit(c.resultCode ?? ExitCode.cancelled);
      return;
    }
    if (c.running) {
      if (c.cancelRequested) return;
      final yes = await confirmCancel(ctx);
      if (yes) await c.cancelRunning();
      return;
    }
    final yes = await confirmCancel(ctx);
    if (yes) c.quit();
  }

  @override
  Widget build(BuildContext context) {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final locale = widget.locale ?? dispatcher.locale;
    final strings = S.forLocale(locale, widget.controller.context.os);
    final highContrast = dispatcher.accessibilityFeatures.highContrast;
    final c = widget.controller;
    return MaterialApp(
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      title: c.isUninstall
          ? strings.uninstallTitle(c.context.productName)
          : strings.windowTitle(c.context.productName),
      locale: Locale(strings.languageCode),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: widget.themeMode,
      theme: buildTheme(Brightness.light, highContrast: highContrast),
      darkTheme: buildTheme(Brightness.dark, highContrast: highContrast),
      home: SetupScope(
        strings: strings,
        child: SetupShell(
          controller: c,
          onClose: () => unawaited(_onCloseRequested()),
        ),
      ),
    );
  }
}

Future<bool> confirmCancel(BuildContext context) async {
  final s = SetupScope.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.cancelHeading),
      content: Text(s.cancelBody),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.cancelNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(s.cancelYes),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Stellt die Texte bereit.
class SetupScope extends InheritedWidget {
  const SetupScope({super.key, required this.strings, required super.child});

  final S strings;

  static S of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SetupScope>()?.strings ??
      S.english;

  @override
  bool updateShouldNotify(SetupScope oldWidget) => oldWidget.strings != strings;
}

/// Fensterinhalt: Markenleiste links, Seite rechts, Knopfleiste unten.
class SetupShell extends StatefulWidget {
  const SetupShell({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final SetupController controller;
  final VoidCallback onClose;

  @override
  State<SetupShell> createState() => _SetupShellState();
}

class _SetupShellState extends State<SetupShell> {
  bool _askingRunning = false;

  SetupController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final apps = c.runningApps;
    if (apps != null && !_askingRunning) {
      _askingRunning = true;
      unawaited(_askRunning(apps));
    }
  }

  Future<void> _askRunning(List<String> apps) async {
    final s = SetupScope.of(context);
    final close = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.runningHeading),
        content: Text(s.runningBody(apps.join(', '))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.runningClose),
          ),
        ],
      ),
    );
    _askingRunning = false;
    await c.answerRunningApps(close: close ?? false);
  }

  String _primaryLabel(S s) => switch (c.step) {
    SetupStep.options => c.isUpdate ? s.update : s.install,
    SetupStep.confirm => s.uninstall,
    SetupStep.done => c.succeeded ? s.finish : s.close,
    _ => s.next,
  };

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final colors = context.colors;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandPanel(controller: c),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FocusTraversalGroup(
                      child: AnimatedSwitcher(
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.topLeft,
                          children: [...previous, ?current],
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(c.step),
                          child: _page(),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(top: BorderSide(color: colors.line)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    child: FocusTraversalGroup(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (c.canGoBack) ...[
                            OutlinedButton(
                              onPressed: c.back,
                              child: Text(s.back),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Bei grossem Text stapeln sich die Knoepfe statt
                          // abgeschnitten zu werden.
                          Expanded(
                            child: OverflowBar(
                              alignment: MainAxisAlignment.end,
                              overflowAlignment: OverflowBarAlignment.end,
                              spacing: 12,
                              overflowSpacing: 8,
                              children: [
                                if (c.step != SetupStep.done)
                                  TextButton(
                                    onPressed:
                                        c.step == SetupStep.progress &&
                                            (c.cancelRequested ||
                                                c.phase == 'finalizing')
                                        ? null
                                        : widget.onClose,
                                    child: Text(s.cancel),
                                  ),
                                if (c.step != SetupStep.progress)
                                  FilledButton(
                                    key: const ValueKey('primary'),
                                    autofocus: true,
                                    onPressed: c.canGoNext
                                        ? () => unawaited(_primary())
                                        : null,
                                    child: Text(_primaryLabel(s)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _primary() async {
    if (c.step == SetupStep.done) {
      final launched = await c.finish();
      if (!launched && mounted) {
        final s = SetupScope.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.launchFailed)));
      }
      return;
    }
    await c.next();
  }

  Widget _page() => switch (c.step) {
    SetupStep.welcome => WelcomePage(controller: c),
    SetupStep.license => LicensePage(controller: c),
    SetupStep.options => OptionsPage(controller: c),
    SetupStep.progress => ProgressPage(controller: c),
    SetupStep.done => DonePage(controller: c),
    SetupStep.confirm => ConfirmUninstallPage(controller: c),
  };
}

/// Linke Leiste: Logo, Marke, Schrittliste (auch für Screenreader).
class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key, required this.controller});

  final SetupController controller;

  String _label(S s, SetupStep step) => switch (step) {
    SetupStep.welcome => s.stepWelcome,
    SetupStep.license => s.stepLicense,
    SetupStep.options => s.stepOptions,
    SetupStep.progress =>
      controller.isUninstall ? s.stepRemoving : s.stepProgress,
    SetupStep.done => s.stepDone,
    SetupStep.confirm => s.stepConfirm,
  };

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final steps = controller.steps;
    final current = controller.stepIndex;
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SetupColors.brandTop, SetupColors.brandBottom],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 24, 24),
      // Bei grossem Text (Windows-Textgroesse) scrollt die Leiste statt
      // abgeschnitten zu werden.
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(child: _content(context, s, steps, current)),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    S s,
    List<SetupStep> steps,
    int current,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                width: 44,
                height: 44,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const SizedBox(width: 44, height: 44),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: const Text(
                  'LINEFM',
                  style: TextStyle(
                    fontFamily: SetupFonts.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          controller.isUninstall ? 'UNINSTALL' : 'RADIO SETUP',
          style: const TextStyle(
            fontFamily: SetupFonts.brand,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 2,
            color: Color(0xFFD9DAE6),
          ),
        ),
        const SizedBox(height: 40),
        Semantics(
          container: true,
          label: s.stepsLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                _StepRow(
                  number: i + 1,
                  label: _label(s, steps[i]),
                  state: i < current
                      ? _StepState.done
                      : i == current
                      ? _StepState.current
                      : _StepState.upcoming,
                  semantics: s.stepOf(i + 1, steps.length),
                ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          s.versionLine(controller.context.version),
          style: const TextStyle(color: Color(0xFFD9DAE6), fontSize: 12),
        ),
        if (controller.context.publisher.isNotEmpty)
          Text(
            controller.context.publisher,
            style: const TextStyle(color: Color(0xFFD9DAE6), fontSize: 12),
          ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.label,
    required this.state,
    required this.semantics,
  });

  final int number;
  final String label;
  final _StepState state;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final active = state == _StepState.current;
    final done = state == _StepState.done;
    final fg = active || done ? Colors.white : const Color(0xFFC3C5D6);
    return Semantics(
      label: '$semantics: $label',
      selected: active,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.white : Colors.transparent,
                border: Border.all(color: fg, width: 1.5),
              ),
              child: done
                  ? Icon(Icons.check, size: 16, color: fg)
                  : Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? SetupColors.brandBottom : fg,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gemeinsamer Seitenrahmen mit Überschrift.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.heading,
    required this.children,
    this.scroll = true,
  });

  final String heading;
  final List<Widget> children;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scroll ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: TextStyle(
              fontFamily: SetupFonts.brand,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.35,
              color: colors.text,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 34, 36, 16),
      child: scroll ? SingleChildScrollView(child: content) : content,
    );
  }
}

class BodyText extends StatelessWidget {
  const BodyText(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.55,
        color: muted ? colors.muted : colors.text,
      ),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = error ? colors.danger : colors.muted;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              size: 20,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(child: BodyText(text)),
          ],
        ),
      ),
    );
  }
}

class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label, style: TextStyle(fontSize: 14, color: colors.text)),
        subtitle: hint == null
            ? null
            : Text(hint!, style: TextStyle(fontSize: 12, color: colors.muted)),
      ),
    );
  }
}

// --- Seiten -----------------------------------------------------------------

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.controller});

  final SetupController controller;

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final ctx = controller.context;
    final existing = controller.existing;
    final String heading;
    final String body;
    if (existing == null) {
      heading = s.welcomeHeading(ctx.productName);
      body = s.welcomeBody(ctx.productName);
    } else {
      heading = s.updateHeading(ctx.productName);
      body = controller.isSameVersion
          ? s.sameVersionBody(ctx.productName, existing.version)
          : s.updateBody(ctx.productName, existing.version, ctx.version);
    }
    return PageFrame(
      heading: heading,
      children: [
        if (controller.isDowngrade)
          Notice(s.downgradeBody(existing!.version, ctx.version), error: true)
        else
          BodyText(body),
        const SizedBox(height: 24),
        BodyText(s.versionLine(ctx.version), muted: true),
        if (ctx.publisher.isNotEmpty)
          BodyText(s.publisherLine(ctx.publisher), muted: true),
        if (ctx.manufacturer.isNotEmpty)
          BodyText(s.manufacturerLine(ctx.manufacturer), muted: true),
        if (ctx.sizeBytes > 0)
          BodyText(s.sizeLine(s.formatBytes(ctx.sizeBytes)), muted: true),
      ],
    );
  }
}

class LicensePage extends StatefulWidget {
  const LicensePage({super.key, required this.controller});

  final SetupController controller;

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final ScrollController _scroll = ScrollController();

  SetupController get controller => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final colors = context.colors;
    final text = controller.licenseText;
    return PageFrame(
      heading: s.licenseHeading,
      scroll: false,
      children: [
        BodyText(s.licenseIntro, muted: true),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.line),
            ),
            child: text == null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: BodyText(s.licenseMissing),
                  )
                : Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        text,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        CheckRow(
          label: s.licenseAccept,
          value: controller.licenseAccepted,
          onChanged: controller.setLicenseAccepted,
        ),
      ],
    );
  }
}

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key, required this.controller});

  final SetupController controller;

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  late final TextEditingController _dir = TextEditingController(
    text: widget.controller.dir,
  );

  @override
  void didUpdateWidget(OptionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_dir.text != widget.controller.dir) {
      _dir.value = TextEditingValue(
        text: widget.controller.dir,
        selection: TextSelection.collapsed(
          offset: widget.controller.dir.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _dir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final s = SetupScope.of(context);
    final c = widget.controller;
    final colors = context.colors;
    final locked = c.locationLocked;
    final dirError = switch (c.validateDir(c.dir)) {
      'empty' => s.folderEmpty,
      'invalid' => s.folderInvalid,
      _ => null,
    };
    Widget scopeTile(
      Scope value,
      String title,
      String hint, {
      bool shield = false,
      bool available = true,
    }) {
      return RadioListTile<Scope>(
        value: value,
        contentPadding: EdgeInsets.zero,
        dense: true,
        enabled: !locked && available,
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: colors.text),
              ),
            ),
            if (shield) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 18,
                color: colors.muted,
              ),
            ],
          ],
        ),
        subtitle: Text(
          hint,
          style: TextStyle(fontSize: 12, color: colors.muted),
        ),
      );
    }

    return PageFrame(
      heading: s.optionsHeading,
      children: [
        if (c.optionsError != null) ...[
          Notice(
            c.optionsError == 'elevation' ? s.elevationDenied : s.startFailed,
            error: true,
          ),
          const SizedBox(height: 16),
        ],
        _Label(s.scopeLabel),
        RadioGroup<Scope>(
          groupValue: c.scope,
          onChanged: (v) {
            if (v != null) c.setScope(v);
          },
          child: Column(
            children: [
              scopeTile(Scope.user, s.scopeUser, s.scopeUserHint),
              scopeTile(
                Scope.machine,
                s.scopeMachine,
                s.scopeMachineHint,
                shield: !c.context.elevated,
                available: c.context.machineScopeAvailable,
              ),
            ],
          ),
        ),
        if (locked) BodyText(s.scopeLocked, muted: true),
        const SizedBox(height: 16),
        _Label(s.folderLabel),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _dir,
                enabled: !locked,
                onChanged: c.setDir,
                style: TextStyle(fontSize: 14, color: colors.text),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: s.folderLabel,
                  errorText: locked ? null : dirError,
                  errorMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: locked
                  ? null
                  : () => unawaited(c.browse(s.folderPickTitle)),
              child: Text(s.browse),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Label(s.shortcutsLabel),
        CheckRow(
          label: s.desktopShortcut,
          value: c.desktop,
          onChanged: c.setDesktop,
        ),
        CheckRow(
          label: s.startMenuShortcut,
          value: c.startMenu,
          onChanged: c.setStartMenu,
        ),
        CheckRow(
          label: s.autostart,
          value: c.autostart,
          onChanged: c.setAutostart,
        ),
        const SizedBox(height: 6),
        BodyText(s.linkSchemeNote, muted: true),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.text,
      ),
    ),
  );
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.controller});

  final SetupController controller;

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final c = controller;
    final value = c.progress;
    final percent = value == null ? null : (value * 100).round();
    final status = c.waitingForElevation
        ? s.waitingForWindows
        : s.phase(c.cancelRequested ? 'rollback' : c.phase);
    return PageFrame(
      heading: c.isUninstall
          ? s.removingHeading(c.context.productName)
          : s.progressHeading(c.context.productName),
      children: [
        const SizedBox(height: 24),
        Semantics(liveRegion: true, child: BodyText(status)),
        const SizedBox(height: 14),
        Semantics(
          label: status,
          value: percent == null ? null : s.percent(percent),
          child: LinearProgressIndicator(value: value),
        ),
        const SizedBox(height: 10),
        if (percent != null)
          ExcludeSemantics(child: BodyText('$percent %', muted: true)),
      ],
    );
  }
}

class DonePage extends StatelessWidget {
  const DonePage({super.key, required this.controller});

  final SetupController controller;

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final c = controller;
    final colors = context.colors;
    final code = c.resultCode ?? ExitCode.failed;
    final name = c.context.productName;
    if (code == ExitCode.ok) {
      return PageFrame(
        heading: c.isUninstall
            ? s.uninstalledHeading(name)
            : c.isUpdate
            ? s.updatedHeading(name)
            : s.doneHeading(name),
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: colors.text),
          const SizedBox(height: 16),
          if (c.isUninstall)
            BodyText(
              c.deleteUserData ? s.uninstalledDeleted : s.uninstalledKept,
            )
          else ...[
            BodyText(s.doneBody(c.installedDir), muted: true),
            const SizedBox(height: 16),
            CheckRow(
              label: s.launchNow,
              value: c.launchAfter,
              onChanged: c.setLaunchAfter,
            ),
          ],
        ],
      );
    }
    final cancelled = code == ExitCode.cancelled;
    return PageFrame(
      heading: cancelled ? s.cancelledHeading : s.failedHeading,
      children: [
        Notice(cancelled ? s.cancelledBody : s.error(code), error: !cancelled),
        if (!cancelled && c.resultMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(
            c.resultMessage,
            style: TextStyle(fontSize: 13, color: colors.text),
          ),
        ],
        if (!cancelled) ...[
          const SizedBox(height: 8),
          BodyText(s.exitCodeLine(code), muted: true),
        ],
        if (c.log.isNotEmpty) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.details, style: TextStyle(color: colors.text)),
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      c.log.join('\n'),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: colors.text,
                        fontFamily: 'Consolas',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ConfirmUninstallPage extends StatelessWidget {
  const ConfirmUninstallPage({super.key, required this.controller});

  final SetupController controller;

  @override
  Widget build(BuildContext context) {
    final s = SetupScope.of(context);
    final c = controller;
    final ctx = c.context;
    final installed = ctx.installed;
    return PageFrame(
      heading: s.uninstallHeading(ctx.productName),
      children: [
        BodyText(
          s.uninstallBody(
            ctx.productName,
            installed?.version ?? ctx.version,
            ctx.target,
          ),
        ),
        const SizedBox(height: 20),
        CheckRow(
          label: s.deleteUserData,
          hint: s.deleteUserDataHint,
          value: c.deleteUserData,
          onChanged: c.setDeleteUserData,
        ),
      ],
    );
  }
}
