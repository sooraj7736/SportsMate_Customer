import 'package:flutter/material.dart';

/// ============================================================
///  AppColors — single source of truth for every color in the
///  SportsMate / NearPlay app.
///
///  Naming convention
///  -----------------
///  surface*      → screen / card backgrounds
///  onSurface*    → text / icons drawn ON a surface
///  border*       → dividers and input borders
///  input*        → form field fill colors
///  sheet*        → bottom-sheet / modal backgrounds
///  nav*          → bottom navigation bar
///  brand*        → primary brand palette
///  sport*        → sport-specific accent palettes
///  semantic*     → success / warning / error / info
///  shadow*       → box shadow colors (pre-built with opacity)
///  overlay*      → semi-transparent overlay helpers
/// ============================================================

class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color brandGreen = Color(0xFF0F5132); // primary
  static const Color brandGreenLight = Color(0xFF43A047); // lighter accent
  static const Color brandGold = Color(0xFFF1C40F); // secondary / achievement
  static const Color brandDeepNavy = Color(0xFF0D1B2A); // splash bg

  // Backward compatibility aliases
  static const Color primaryGreen = brandGreen;
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color achievementGold = brandGold;
  static const Color textLight = Color(0xFF1B2631);
  static const Color textDark = Color(0xFFECF0F1);
  static const Color subTextDark = Color(0xFF8EA5B8);
  static const Color subTextLight = Color(0xFF6B7280);
  static const Color deepPitch = brandDeepNavy;
  static const Color overlayWhiteLight = Color(0x29FFFFFF);

  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF8F9F9); // scaffold bg
  static const Color cardLight = Color(0xFFFFFFFF); // card / sheet bg
  static const Color cardSubtleLight = Color(0xFFF0F2F5); // subtle card variant
  static const Color inputFillLight = Color(0xFFF0F2F5); // text field fill
  static const Color borderLight = Color(0xFFE0E0E0); // dividers / borders
  static const Color sheetLight = Color(0xFFFFFFFF); // bottom sheet

  // ── Dark Theme Surfaces ───────────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0F161C); // scaffold bg
  static const Color cardDark = Color(0xFF1A2332); // card bg
  static const Color cardSubtleDark = Color(0xFF222E3C); // subtle variant
  static const Color inputFillDark = Color(0xFF1E2C3A); // text field fill
  static const Color borderDark = Color(0xFF2D3D50); // dividers / borders
  static const Color sheetDark = Color(0xFF1A2332); // bottom sheet

  // ── Light Theme Text ──────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1B2631); // body text
  static const Color textSecondaryLight = Color(0xFF6B7280); // muted / captions
  static const Color textHintLight = Color(0xFF9CA3AF); // placeholder text
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // ── Dark Theme Text ───────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFECF0F1); // body text
  static const Color textSecondaryDark = Color(0xFF8EA5B8); // muted / captions
  static const Color textHintDark = Color(0xFF5C7A96); // placeholder text
  static const Color textDisabledDark = Color(0xFF4A5568);

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  static const Color navBgLight = Color(0xFFFFFFFF);
  static const Color navBgDark = Color(0xFF1A2332);
  static const Color navSelectedLight = Color(0xFF0F5132); // brandGreen
  static const Color navSelectedDark = Color(0xFF43A047); // brandGreenLight
  static const Color navUnselectedLight = Color(0xFF9CA3AF);
  static const Color navUnselectedDark = Color(0xFF5C7A96);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color semanticSuccess = Color(0xFF27AE60);
  static const Color semanticWarning = Color(0xFFF39C12);
  static const Color semanticError = Color(0xFFE74C3C);
  static const Color semanticInfo = Color(0xFF2980B9);

  // Notification unread highlight (light / dark)
  static const Color notifUnreadLight = Color(
    0xFFEBF5FB,
  ); // very light blue tint
  static const Color notifUnreadDark = Color(0xFF162234); // dark blue tint

  // ── Football Live Score Screen ────────────────────────────────────────────
  static const Color footballHeaderTop = Color(
    0xFF1B5E20,
  ); // header gradient top
  static const Color footballHeaderBottom = Color(
    0xFF388E3C,
  ); // header gradient bottom

  static const Color footballHostCardTop = Color(
    0xFF2E7D32,
  ); // host score card top
  static const Color footballHostCardBot = Color(
    0xFF43A047,
  ); // host score card bottom
  static const Color footballHostText = Color(0xFFFFFFFF);

  static const Color footballGuestCardTop = Color(
    0xFFF1F8E9,
  ); // guest score card top
  static const Color footballGuestCardBot = Color(
    0xFFDCEDC8,
  ); // guest score card bottom
  static const Color footballGuestText = Color(0xFF1B5E20);

  static const Color footballBorder = Color(0xFFA5D6A7); // green.shade200
  static const Color footballIncidentBg = Color(0xFFF1F8E9); // green.shade50
  static const Color footballIncidentBorder = Color(
    0xFFC8E6C9,
  ); // green.shade100

  static const Color footballClockAccent = Color(0xFF69F0AE); // greenAccent
  static const Color footballTimerPlay = Color(
    0xFF388E3C,
  ); // start/resume button
  static const Color footballTimerPause = Color(0xFFB71C1C); // pause button

  static const Color footballStoppageChip = Color(0x2EFFFFFF);
  static const Color footballPresetChip = Color(0x4DFF8F00);
  static const Color stoppageRedBg = Color(0x33FF5252);
  static const Color footballMatchCardBg = cardLight;
  static const Color footballIncidentsBg = cardSubtleLight;
  static const Color footballIncidentsBorder = borderLight;
  static const Color footballScoreButtonBg = footballTimerPlay;

  static const Color footballHostTextColor = footballHostText;
  static const Color footballGuestTextColor = footballGuestText;
  static const Color footballHostGradientTop = footballHeaderTop;
  static const Color footballHostGradientBottom = footballHeaderBottom;
  static const Color footballGuestGradientTop = footballGuestCardTop;
  static const Color footballGuestGradientBottom = footballGuestCardBot;
  static const Color footballBorderColor = footballBorder;
  static const Color footballHeaderGradientTop = footballHeaderTop;
  static const Color footballHeaderGradientBottom = footballHeaderBottom;
  static const Color footballStoppageChipBg = footballStoppageChip;
  static const Color footballPresetChipBg = footballPresetChip;
  static const Color footballClockGlow = footballClockAccent;
  static const Color footballTimerRunningBg = footballTimerPlay;
  static const Color footballTimerStoppedBg = footballTimerPause;

  // Event chip colour pairs (background / text)
  static const Color eventGoalBg = Color(0xFFFFE0B2);
  static const Color eventGoalText = Color(0xFFE65100);
  static const Color eventYellowCardBg = Color(0xFFFFF9C4);
  static const Color eventYellowCardText = Color(0xFFFF6F00);
  static const Color eventRedCardBg = Color(0xFFFFCDD2);
  static const Color eventRedCardText = Color(0xFFB71C1C);
  static const Color eventYellowBg = eventYellowCardBg;
  static const Color eventYellowText = eventYellowCardText;
  static const Color eventRedBg = eventRedCardBg;
  static const Color eventRedText = eventRedCardText;
  static const Color eventFoulBg = Color(0xFFE3F2FD);
  static const Color eventFoulText = Color(0xFF0D47A1);
  static const Color eventPenaltyBg = Color(0xFFC8E6C9);
  static const Color eventPenaltyText = Color(0xFF1B5E20);
  static const Color eventOffsideBg = Color(0xFFF3E5F5);
  static const Color eventOffsideText = Color(0xFF4A148C);
  static const Color eventCornerBg = Color(0xFFE0F2F1);
  static const Color eventCornerText = Color(0xFF004D40);

  // ── Basketball Live Score Screen ──────────────────────────────────────────
  static const Color basketballHeaderTop = Color(0xFF212121); // grey.shade900
  static const Color basketballHeaderBot = Color(0xFF000000);
  static const Color basketballAccent = Color(0xFFEF6C00); // orange.shade800

  static const Color basketballHostTop = Color(0xFFEF6C00);
  static const Color basketballHostBot = Color(0xFFFB8C00);
  static const Color basketballGuestTop = Color(0xFF1565C0);
  static const Color basketballGuestBot = Color(0xFF1E88E5);

  static const Color basketballClockAccent = Color(0xFFFFAB40); // orangeAccent
  static const Color basketballTimerPlay = Color(0xFFFFAB40); // start
  static const Color basketballTimerPause = Color(0xFFFF5252); // redAccent

  static const Color basketballQtrSelected = Color(0xFFEF6C00);
  static const Color basketballQtrDefault = Color(0x1AFFFFFF); // white10
  static const Color basketballLogButton = Color(0xFFEF6C00);
  static const Color basketballBonusBadge = Color(0xFFF44336);

  static const Color basketballHostGradientTop = basketballHostTop;
  static const Color basketballHostGradientBottom = basketballHostBot;
  static const Color basketballGuestGradientTop = basketballGuestTop;
  static const Color basketballGuestGradientBottom = basketballGuestBot;
  static const Color basketballAccentOrange = basketballAccent;
  static const Color basketballHeaderGradientTop = basketballHeaderTop;
  static const Color basketballHeaderGradientBottom = basketballHeaderBot;
  static const Color basketballTimerRunningBg = basketballTimerPlay;
  static const Color basketballTimerStoppedBg = basketballTimerPause;
  static const Color basketballClockGlow = basketballClockAccent;
  static const Color basketballBonusBadgeBg = basketballBonusBadge;
  static const Color basketballQuarterSelectedBg = basketballQtrSelected;
  static const Color basketballQuarterDefaultBg = basketballQtrDefault;
  static const Color basketballLogButtonBg = basketballLogButton;
  static const Color basketballCardBg = cardLight;
  static const Color basketballCardBorder = borderLight;
  static const Color basketballIncidentsBg = cardSubtleLight;
  static const Color basketballIncidentsBorder = borderLight;

  // ── Shadows (pre-made with opacity) ──────────────────────────────────────
  static const Color shadowXLight = Color(0x0A000000); // 4% black
  static const Color shadowLight = Color(0x0D000000); // 5% black
  static const Color shadowMedium = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x24000000); // 14% black

  // ── Overlay helpers ───────────────────────────────────────────────────────
  static const Color overlayWhiteSubtle = Color(0x1FFFFFFF); // 12%
  static const Color overlayWhiteMid = Color(0x29FFFFFF); // 16%
  static const Color overlayWhiteStrong = Color(0x47FFFFFF); // 28%
  static const Color stoppageHighlight = Color(0x33FF5252); // redAccent 20%
}
