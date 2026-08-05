import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons/heroicons.dart';

/// Central icon mapper for switching icon packs.
///
/// `iconPack` values come from ThemeSetting.iconPack:
/// - solar        → falls back to material (solar_icons package removed)
/// - fontawesome
/// - bootstrap
/// - heroicons
/// - material
/// - cupertino
class IconMapper {
  static const Set<String> _materialFallbackKeys = {
    // UI clarity/consistency keys where we intentionally keep Material.
    'time',
    'speed',
    'copy',
    'code',
    'inbox',
    'data-object',
    'image-not-supported',

    // POS/payment related
    'money',
    'credit-card',
    'receipt',
    'gift-card',
    'account-balance',
    'paypal',
    'payment',
    'credit-score',
  };

  static String normalizePack(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return 'material';
    if (v.contains('font')) return 'fontawesome';
    if (v.contains('boot')) return 'bootstrap';
    if (v.contains('hero')) return 'heroicons';
    if (v.contains('material')) return 'material';
    if (v.contains('cupertino') || v == 'ios' || v.contains('apple')) {
      return 'cupertino';
    }
    // solar package removed → treat as material
    if (v.contains('solar')) return 'material';
    return v;
  }

  static Widget icon(
    String iconKey, {
    required String? iconPack,
    Color? color,
    double? size,
  }) {
    final pack = normalizePack(iconPack);

    // For some keys we intentionally keep Material icons even when the user
    // switches packs (for better recognizability/pattern consistency).
    if (pack != 'material' && _materialFallbackKeys.contains(iconKey)) {
      return Icon(_material(iconKey), color: color, size: size);
    }

    switch (pack) {
      case 'fontawesome':
        return Icon(_fontAwesome(iconKey), color: color, size: size);
      case 'bootstrap':
        return Icon(_bootstrap(iconKey), color: color, size: size);
      case 'heroicons':
        return HeroIcon(_heroicons(iconKey), color: color, size: size);
      case 'material':
        return Icon(_material(iconKey), color: color, size: size);
      case 'cupertino':
        return Icon(_cupertino(iconKey), color: color, size: size);
      default:
        // Fall back to material
        return Icon(_material(iconKey), color: color, size: size);
    }
  }

  // ------------------------
  // Per-pack mappings
  // ------------------------

  static IconData _fontAwesome(String key) {
    switch (key) {
      case 'dashboard':
        return FontAwesomeIcons.houseChimney.data;
      case 'whatsapp':
        return FontAwesomeIcons.squareWhatsapp.data;
      case 'product':
        return FontAwesomeIcons.boxArchive.data;
      case 'purchase':
        return FontAwesomeIcons.solidCreditCard.data;
      case 'sale':
        return FontAwesomeIcons.cartShopping.data;
      case 'manufacturing':
        return FontAwesomeIcons.industry.data;
      case 'expense':
        return FontAwesomeIcons.moneyBill.data;
      case 'income':
        return FontAwesomeIcons.sackDollar.data;
      case 'quotation':
        return FontAwesomeIcons.fileInvoice.data;
      case 'transfer':
        return FontAwesomeIcons.rightLeft.data;
      case 'return':
        return FontAwesomeIcons.reply.data;
      case 'accounting':
        return FontAwesomeIcons.calculator.data;
      case 'hrm':
        return FontAwesomeIcons.users.data;
      case 'people':
        return FontAwesomeIcons.usersGear.data;
      case 'people-setting':
        return FontAwesomeIcons.userGear.data;
      case 'addons':
        return FontAwesomeIcons.puzzlePiece.data;
      case 'reports':
        return FontAwesomeIcons.fileCircleCheck.data;
      case 'settings':
        return FontAwesomeIcons.gear.data;
      case 'logout':
        return FontAwesomeIcons.rightFromBracket.data;
      case 'plus':
        return FontAwesomeIcons.plus.data;
      case 'bug':
        return FontAwesomeIcons.bug.data;
      case 'delete':
        return FontAwesomeIcons.trash.data;
      case 'edit':
        return FontAwesomeIcons.pen.data;
      case 'view':
        return FontAwesomeIcons.eye.data;
      case 'network':
        return FontAwesomeIcons.wifi.data;
      case 'file-import':
        return FontAwesomeIcons.fileImport.data;

      // Screen-level UI icons
      case 'appearance-system':
        return FontAwesomeIcons.circleHalfStroke.data;
      case 'appearance-light':
        return FontAwesomeIcons.sun.data;
      case 'appearance-dark':
        return FontAwesomeIcons.moon.data;
      case 'drawer':
        return FontAwesomeIcons.bars.data;

      case 'status-success':
        return FontAwesomeIcons.circleCheck.data;
      case 'status-failed':
        return FontAwesomeIcons.circleXmark.data;
      case 'status-warning':
        return FontAwesomeIcons.triangleExclamation.data;
      case 'status-pending':
        return FontAwesomeIcons.clock.data;

      case 'time':
        return FontAwesomeIcons.clock.data;
      case 'speed':
        return FontAwesomeIcons.gaugeHigh.data;
      case 'close':
        return FontAwesomeIcons.xmark.data;
      case 'upload':
        return FontAwesomeIcons.upload.data;
      case 'download':
        return FontAwesomeIcons.download.data;
      case 'http':
        return FontAwesomeIcons.globe.data;
      case 'check':
        return FontAwesomeIcons.check.data;
      case 'copy':
        return FontAwesomeIcons.copy.data;
      case 'data-object':
        return FontAwesomeIcons.database.data;
      case 'inbox':
        return FontAwesomeIcons.inbox.data;
      case 'error-outline':
        return FontAwesomeIcons.circleExclamation.data;
      case 'code':
        return FontAwesomeIcons.code.data;
      case 'email':
        return FontAwesomeIcons.envelope.data;
      case 'phone':
        return FontAwesomeIcons.phone.data;

      case 'chevron-right':
        return FontAwesomeIcons.chevronRight.data;

      case 'error':
        return FontAwesomeIcons.triangleExclamation.data;
      case 'qr-scanner':
        return FontAwesomeIcons.qrcode.data;

      case 'printer':
        return FontAwesomeIcons.print.data;
      case 'check-circle':
        return FontAwesomeIcons.circleCheck.data;
      case 'close-circle':
        return FontAwesomeIcons.circleXmark.data;
      case 'file-text':
        return FontAwesomeIcons.fileLines.data;
      case 'arrow-left':
        return FontAwesomeIcons.arrowLeft.data;

      case 'refresh':
        return FontAwesomeIcons.arrowsRotate.data;
      case 'document-text':
        return FontAwesomeIcons.fileLines.data;
      case 'server':
        return FontAwesomeIcons.server.data;
      case 'key':
        return FontAwesomeIcons.key.data;

      // Widget-level UI icons
      case 'info':
        return FontAwesomeIcons.circleInfo.data;
      case 'help':
        return FontAwesomeIcons.circleQuestion.data;
      case 'plus-circle':
        return FontAwesomeIcons.circlePlus.data;
      case 'search':
        return FontAwesomeIcons.magnifyingGlass.data;
      case 'view-off':
        return FontAwesomeIcons.eyeSlash.data;
      case 'warning':
        return FontAwesomeIcons.triangleExclamation.data;
      case 'more':
        return FontAwesomeIcons.ellipsisVertical.data;
      case 'image-not-supported':
        return FontAwesomeIcons.image.data;
      case 'broken-image':
        return FontAwesomeIcons.image.data;
      case 'person':
        return FontAwesomeIcons.user.data;
      case 'link':
        return FontAwesomeIcons.link.data;
      case 'fullscreen':
        return FontAwesomeIcons.expand.data;
      case 'chevron-left':
        return FontAwesomeIcons.chevronLeft.data;
      case 'arrow-right':
        return FontAwesomeIcons.arrowRight.data;
      case 'bluetooth-connected':
        return FontAwesomeIcons.bluetooth.data;

      // POS/payment related
      case 'money':
        return FontAwesomeIcons.dollarSign.data;
      case 'credit-card':
        return FontAwesomeIcons.creditCard.data;
      case 'receipt':
        return FontAwesomeIcons.receipt.data;
      case 'gift-card':
        return FontAwesomeIcons.gift.data;
      case 'account-balance':
        return FontAwesomeIcons.buildingColumns.data;
      case 'star':
        return FontAwesomeIcons.star.data;
      case 'paypal':
        return FontAwesomeIcons.paypal.data;
      case 'payment':
        return FontAwesomeIcons.creditCard.data;
      case 'credit-score':
        return FontAwesomeIcons.shield.data;
      case 'calendar':
        return FontAwesomeIcons.calendarDays.data;
      case 'cancel':
        return FontAwesomeIcons.ban.data;
      case 'edit-document':
        return FontAwesomeIcons.filePen.data;
      case 'drafts':
        return FontAwesomeIcons.fileLines.data;
      case 'history':
        return FontAwesomeIcons.clockRotateLeft.data;
      case 'store':
        return FontAwesomeIcons.store.data;
      case 'category':
        return FontAwesomeIcons.tags.data;
      case 'image':
        return FontAwesomeIcons.image.data;

      // Misc
      case 'magic-wand':
        return FontAwesomeIcons.wandMagicSparkles.data;
      case 'chart-square':
        return FontAwesomeIcons.chartColumn.data;
      case 'trophy':
        return FontAwesomeIcons.trophy.data;
      case 'double-arrow-right':
        return FontAwesomeIcons.anglesRight.data;
      case 'double-arrow-left':
        return FontAwesomeIcons.anglesLeft.data;
      default:
        return FontAwesomeIcons.circleQuestion.data;
    }
  }

  static IconData _bootstrap(String key) {
    switch (key) {
      case 'dashboard':
        return BootstrapIcons.house;
      case 'whatsapp':
        return BootstrapIcons.whatsapp;
      case 'product':
        return BootstrapIcons.box_seam;
      case 'purchase':
        return BootstrapIcons.credit_card_2_front;
      case 'sale':
        return BootstrapIcons.cart_check;
      case 'manufacturing':
        return BootstrapIcons.shop;
      case 'expense':
        return BootstrapIcons.cash_coin;
      case 'income':
        return BootstrapIcons.piggy_bank;
      case 'quotation':
        return BootstrapIcons.file_earmark_text;
      case 'transfer':
        return BootstrapIcons.arrow_left_right;
      case 'return':
        return BootstrapIcons.arrow_return_left;
      case 'accounting':
        return BootstrapIcons.calculator;
      case 'hrm':
        return BootstrapIcons.people;
      case 'people':
        return BootstrapIcons.person;
      case 'people-setting':
        return BootstrapIcons.person_gear;
      case 'addons':
        return BootstrapIcons.plugin;
      case 'reports':
        return BootstrapIcons.file_text;
      case 'settings':
        return BootstrapIcons.gear;
      case 'logout':
        return BootstrapIcons.box_arrow_right;
      case 'plus':
        return BootstrapIcons.plus;
      case 'bug':
        return BootstrapIcons.bug;
      case 'delete':
        return BootstrapIcons.trash;
      case 'edit':
        return BootstrapIcons.pen;
      case 'view':
        return BootstrapIcons.eye;
      case 'network':
        return BootstrapIcons.wifi;
      case 'file-import':
        return BootstrapIcons.file_arrow_up;

      // Screen-level UI icons
      case 'appearance-system':
        return BootstrapIcons.circle_half;
      case 'appearance-light':
        return BootstrapIcons.sun;
      case 'appearance-dark':
        return BootstrapIcons.moon;
      case 'drawer':
        return BootstrapIcons.list;

      case 'status-success':
        return BootstrapIcons.check_circle;
      case 'status-failed':
        return BootstrapIcons.x_circle;
      case 'status-warning':
        return BootstrapIcons.exclamation_triangle;
      case 'status-pending':
        return BootstrapIcons.clock;

      case 'time':
        return BootstrapIcons.clock;
      case 'speed':
        return BootstrapIcons.speedometer;
      case 'close':
        return BootstrapIcons.x_lg;
      case 'upload':
        return BootstrapIcons.upload;
      case 'download':
        return BootstrapIcons.download;
      case 'http':
        return BootstrapIcons.globe;
      case 'check':
        return BootstrapIcons.check;
      case 'copy':
        return BootstrapIcons.clipboard;
      case 'data-object':
        return BootstrapIcons.database;
      case 'inbox':
        return BootstrapIcons.inbox;
      case 'error-outline':
        return BootstrapIcons.exclamation_circle;
      case 'code':
        return BootstrapIcons.code;
      case 'email':
        return BootstrapIcons.envelope;
      case 'phone':
        return BootstrapIcons.phone;

      case 'chevron-right':
        return BootstrapIcons.chevron_right;

      case 'error':
        return BootstrapIcons.exclamation_triangle;
      case 'qr-scanner':
        return BootstrapIcons.qr_code_scan;

      case 'printer':
        return BootstrapIcons.printer;
      case 'check-circle':
        return BootstrapIcons.check_circle;
      case 'close-circle':
        return BootstrapIcons.x_circle;
      case 'file-text':
        return BootstrapIcons.file_text;
      case 'arrow-left':
        return BootstrapIcons.arrow_left;

      case 'refresh':
        return BootstrapIcons.arrow_clockwise;
      case 'document-text':
        return BootstrapIcons.file_text;
      case 'server':
        return BootstrapIcons.server;
      case 'key':
        return BootstrapIcons.key;

      // Widget-level UI icons
      case 'info':
        return BootstrapIcons.info_circle;
      case 'help':
        return BootstrapIcons.question_circle;
      case 'plus-circle':
        return BootstrapIcons.plus_circle;
      case 'search':
        return BootstrapIcons.search;
      case 'view-off':
        return BootstrapIcons.eye_slash;
      case 'warning':
        return BootstrapIcons.exclamation_triangle;
      case 'more':
        return BootstrapIcons.three_dots_vertical;
      case 'image-not-supported':
        return BootstrapIcons.image;
      case 'broken-image':
        return BootstrapIcons.image;
      case 'person':
        return BootstrapIcons.person;
      case 'link':
        return BootstrapIcons.link_45deg;
      case 'fullscreen':
        return BootstrapIcons.fullscreen;
      case 'chevron-left':
        return BootstrapIcons.chevron_left;
      case 'arrow-right':
        return BootstrapIcons.arrow_right;
      case 'bluetooth-connected':
        return BootstrapIcons.bluetooth;

      // POS/payment related
      case 'money':
        return BootstrapIcons.currency_dollar;
      case 'credit-card':
        return BootstrapIcons.credit_card;
      case 'receipt':
        return BootstrapIcons.receipt;
      case 'gift-card':
        return BootstrapIcons.gift;
      case 'account-balance':
        return BootstrapIcons.bank;
      case 'star':
        return BootstrapIcons.star;
      case 'paypal':
        return BootstrapIcons.paypal;
      case 'payment':
        return BootstrapIcons.credit_card;
      case 'credit-score':
        return BootstrapIcons.shield_check;
      case 'calendar':
        return BootstrapIcons.calendar_event;
      case 'cancel':
        return BootstrapIcons.x_circle;
      case 'edit-document':
        return BootstrapIcons.pencil_square;
      case 'drafts':
        return BootstrapIcons.envelope;
      case 'history':
        return BootstrapIcons.clock_history;
      case 'store':
        return BootstrapIcons.shop;
      case 'category':
        return BootstrapIcons.tags;
      case 'image':
        return BootstrapIcons.image;

      // Misc
      case 'magic-wand':
        return BootstrapIcons.magic;
      case 'chart-square':
        return BootstrapIcons.bar_chart;
      case 'trophy':
        return BootstrapIcons.trophy;
      case 'double-arrow-right':
        return BootstrapIcons.chevron_double_right;
      case 'double-arrow-left':
        return BootstrapIcons.chevron_double_left;
      default:
        return BootstrapIcons.question_circle;
    }
  }

  static HeroIcons _heroicons(String key) {
    switch (key) {
      case 'dashboard':
        return HeroIcons.home;
      case 'whatsapp':
        return HeroIcons.chatBubbleLeftRight;
      case 'product':
        return HeroIcons.cube;
      case 'purchase':
        return HeroIcons.creditCard;
      case 'sale':
        return HeroIcons.shoppingCart;
      case 'manufacturing':
        return HeroIcons.buildingOffice2;
      case 'expense':
        return HeroIcons.banknotes;
      case 'income':
        return HeroIcons.currencyDollar;
      case 'quotation':
        return HeroIcons.documentText;
      case 'transfer':
        return HeroIcons.arrowsRightLeft;
      case 'return':
        return HeroIcons.arrowUturnLeft;
      case 'accounting':
        return HeroIcons.calculator;
      case 'hrm':
        return HeroIcons.users;
      case 'people':
        return HeroIcons.userGroup;
      case 'people-setting':
        return HeroIcons.user;
      case 'addons':
        return HeroIcons.puzzlePiece;
      case 'reports':
        return HeroIcons.documentChartBar;
      case 'settings':
        return HeroIcons.cog6Tooth;
      case 'logout':
        return HeroIcons.arrowRightOnRectangle;
      case 'plus':
        return HeroIcons.plus;
      case 'bug':
        return HeroIcons.cpuChip;
      case 'delete':
        return HeroIcons.trash;
      case 'edit':
        return HeroIcons.pencil;
      case 'view':
        return HeroIcons.eye;
      case 'network':
        return HeroIcons.wifi;
      case 'file-import':
        return HeroIcons.arrowUpOnSquare;

      // Screen-level UI icons
      case 'appearance-system':
        return HeroIcons.cog;
      case 'appearance-light':
        return HeroIcons.sun;
      case 'appearance-dark':
        return HeroIcons.moon;
      case 'drawer':
        return HeroIcons.bars2;

      case 'status-success':
        return HeroIcons.checkCircle;
      case 'status-failed':
        return HeroIcons.xCircle;
      case 'status-warning':
        return HeroIcons.exclamationTriangle;
      case 'status-pending':
        return HeroIcons.clock;

      case 'time':
        return HeroIcons.clock;
      case 'speed':
        return HeroIcons.bolt;
      case 'close':
        return HeroIcons.xMark;
      case 'upload':
        return HeroIcons.arrowUpTray;
      case 'download':
        return HeroIcons.arrowDownTray;
      case 'http':
        return HeroIcons.globeAlt;
      case 'check':
        return HeroIcons.check;
      case 'copy':
        return HeroIcons.clipboard;
      case 'data-object':
        return HeroIcons.circleStack;
      case 'inbox':
        return HeroIcons.inbox;
      case 'error-outline':
        return HeroIcons.exclamationCircle;
      case 'code':
        return HeroIcons.codeBracket;
      case 'email':
        return HeroIcons.envelope;
      case 'phone':
        return HeroIcons.phone;

      case 'chevron-right':
        return HeroIcons.chevronRight;

      case 'error':
        return HeroIcons.exclamationTriangle;
      case 'qr-scanner':
        return HeroIcons.qrCode;

      case 'printer':
        return HeroIcons.printer;
      case 'check-circle':
        return HeroIcons.checkCircle;
      case 'close-circle':
        return HeroIcons.xCircle;
      case 'file-text':
        return HeroIcons.documentText;
      case 'arrow-left':
        return HeroIcons.arrowLeft;

      case 'refresh':
        return HeroIcons.arrowPath;
      case 'document-text':
        return HeroIcons.documentText;
      case 'server':
        return HeroIcons.server;
      case 'key':
        return HeroIcons.key;

      // Widget-level UI icons
      case 'info':
        return HeroIcons.informationCircle;
      case 'help':
        return HeroIcons.questionMarkCircle;
      case 'plus-circle':
        return HeroIcons.plusCircle;
      case 'search':
        return HeroIcons.magnifyingGlass;
      case 'view-off':
        return HeroIcons.eyeSlash;
      case 'warning':
        return HeroIcons.exclamationTriangle;
      case 'more':
        return HeroIcons.ellipsisVertical;
      case 'image-not-supported':
        return HeroIcons.photo;
      case 'broken-image':
        return HeroIcons.photo;
      case 'person':
        return HeroIcons.user;
      case 'link':
        return HeroIcons.link;
      case 'fullscreen':
        return HeroIcons.arrowsPointingOut;
      case 'chevron-left':
        return HeroIcons.chevronLeft;
      case 'arrow-right':
        return HeroIcons.arrowRight;
      case 'bluetooth-connected':
        return HeroIcons.signal;

      // POS/payment related
      case 'money':
        return HeroIcons.banknotes;
      case 'credit-card':
        return HeroIcons.creditCard;
      case 'receipt':
        return HeroIcons.documentText;
      case 'gift-card':
        return HeroIcons.gift;
      case 'account-balance':
        return HeroIcons.buildingLibrary;
      case 'star':
        return HeroIcons.star;
      case 'paypal':
        return HeroIcons.banknotes;
      case 'payment':
        return HeroIcons.creditCard;
      case 'credit-score':
        return HeroIcons.shieldCheck;
      case 'calendar':
        return HeroIcons.calendarDays;
      case 'cancel':
        return HeroIcons.xMark;
      case 'edit-document':
        return HeroIcons.pencilSquare;
      case 'drafts':
        return HeroIcons.documentText;
      case 'history':
        return HeroIcons.clock;
      case 'store':
        return HeroIcons.buildingStorefront;
      case 'category':
        return HeroIcons.tag;
      case 'image':
        return HeroIcons.photo;

      // Misc
      case 'magic-wand':
        return HeroIcons.sparkles;
      case 'chart-square':
        return HeroIcons.chartBarSquare;
      case 'trophy':
        return HeroIcons.trophy;
      case 'double-arrow-right':
        return HeroIcons.chevronDoubleRight;
      case 'double-arrow-left':
        return HeroIcons.chevronDoubleLeft;
      default:
        return HeroIcons.questionMarkCircle;
    }
  }

  static IconData _cupertino(String key) {
    switch (key) {
      case 'dashboard':
        return CupertinoIcons.home;
      case 'whatsapp':
        return CupertinoIcons.chat_bubble;
      case 'product':
        return CupertinoIcons.cube_box;
      case 'purchase':
        return CupertinoIcons.creditcard;
      case 'sale':
        return CupertinoIcons.cart;
      case 'manufacturing':
        return CupertinoIcons.hammer;
      case 'expense':
        return CupertinoIcons.list_dash;
      case 'income':
        return CupertinoIcons.money_dollar_circle;
      case 'quotation':
        return CupertinoIcons.doc_text;
      case 'transfer':
        return CupertinoIcons.arrow_right_arrow_left;
      case 'return':
        return CupertinoIcons.arrow_uturn_left;
      case 'accounting':
        return CupertinoIcons.sum;
      case 'hrm':
        return CupertinoIcons.person_2;
      case 'people':
        return CupertinoIcons.person;
      case 'people-setting':
        return CupertinoIcons.person_circle;
      case 'addons':
        return CupertinoIcons.square_grid_2x2;
      case 'reports':
        return CupertinoIcons.chart_bar;
      case 'settings':
        return CupertinoIcons.gear;
      case 'logout':
        return CupertinoIcons.square_arrow_right;
      case 'plus':
        return CupertinoIcons.plus;
      case 'bug':
        return CupertinoIcons.lab_flask;
      case 'delete':
        return CupertinoIcons.delete;
      case 'edit':
        return CupertinoIcons.pencil;
      case 'view':
        return CupertinoIcons.eye;
      case 'network':
        return CupertinoIcons.wifi;
      case 'file-import':
        return CupertinoIcons.arrow_down_doc;

      // Screen-level UI icons
      case 'appearance-system':
        return CupertinoIcons.device_phone_portrait;
      case 'appearance-light':
        return CupertinoIcons.sun_max;
      case 'appearance-dark':
        return CupertinoIcons.moon;
      case 'drawer':
        return CupertinoIcons.bars;

      case 'status-success':
        return CupertinoIcons.check_mark_circled;
      case 'status-failed':
        return CupertinoIcons.xmark_circle;
      case 'status-warning':
        return CupertinoIcons.exclamationmark_triangle;
      case 'status-pending':
        return CupertinoIcons.clock;

      case 'time':
        return CupertinoIcons.time;
      case 'speed':
        return CupertinoIcons.speedometer;
      case 'close':
        return CupertinoIcons.xmark;
      case 'upload':
        return CupertinoIcons.cloud_upload;
      case 'download':
        return CupertinoIcons.cloud_download;
      case 'http':
        return CupertinoIcons.globe;
      case 'check':
        return CupertinoIcons.check_mark;
      case 'copy':
        return CupertinoIcons.doc_on_doc;
      case 'data-object':
        return CupertinoIcons.cube;
      case 'inbox':
        return CupertinoIcons.tray;
      case 'error-outline':
        return CupertinoIcons.exclamationmark_circle;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'email':
        return CupertinoIcons.envelope;
      case 'phone':
        return CupertinoIcons.phone;

      case 'chevron-right':
        return CupertinoIcons.chevron_right;

      case 'error':
        return CupertinoIcons.exclamationmark_circle;
      case 'qr-scanner':
        return CupertinoIcons.qrcode_viewfinder;

      case 'printer':
        return CupertinoIcons.printer;
      case 'check-circle':
        return CupertinoIcons.check_mark_circled;
      case 'close-circle':
        return CupertinoIcons.xmark_circle;
      case 'file-text':
        return CupertinoIcons.doc_text;
      case 'arrow-left':
        return CupertinoIcons.back;

      case 'refresh':
        return CupertinoIcons.refresh;
      case 'document-text':
        return CupertinoIcons.doc_text;
      case 'server':
        return CupertinoIcons.cloud;
      case 'key':
        return CupertinoIcons.lock;

      // Widget-level UI icons
      case 'info':
        return CupertinoIcons.info;
      case 'help':
        return CupertinoIcons.question_circle;
      case 'plus-circle':
        return CupertinoIcons.plus_circle;
      case 'search':
        return CupertinoIcons.search;
      case 'view-off':
        return CupertinoIcons.eye_slash;
      case 'warning':
        return CupertinoIcons.exclamationmark_triangle;
      case 'more':
        return CupertinoIcons.ellipsis_vertical;
      case 'image-not-supported':
        return CupertinoIcons.photo;
      case 'broken-image':
        return CupertinoIcons.photo;
      case 'person':
        return CupertinoIcons.person;
      case 'link':
        return CupertinoIcons.link;
      case 'fullscreen':
        return CupertinoIcons.fullscreen;
      case 'chevron-left':
        return CupertinoIcons.chevron_left;
      case 'arrow-right':
        return CupertinoIcons.arrow_right;
      case 'bluetooth-connected':
        return CupertinoIcons.bluetooth;

      // POS/payment related
      case 'money':
        return CupertinoIcons.money_dollar;
      case 'credit-card':
        return CupertinoIcons.creditcard;
      case 'receipt':
        return CupertinoIcons.doc_text;
      case 'gift-card':
        return CupertinoIcons.gift;
      case 'account-balance':
        return CupertinoIcons.building_2_fill;
      case 'star':
        return CupertinoIcons.star;
      case 'paypal':
        return CupertinoIcons.creditcard;
      case 'payment':
        return CupertinoIcons.creditcard;
      case 'credit-score':
        return CupertinoIcons.check_mark_circled;
      case 'calendar':
        return CupertinoIcons.calendar;
      case 'cancel':
        return CupertinoIcons.xmark_circle;
      case 'edit-document':
        return CupertinoIcons.doc_text;
      case 'drafts':
        return CupertinoIcons.doc_plaintext;
      case 'history':
        return CupertinoIcons.clock;
      case 'store':
        return CupertinoIcons.bag;
      case 'category':
        return CupertinoIcons.square_grid_2x2;
      case 'image':
        return CupertinoIcons.photo;

      // Misc
      case 'magic-wand':
        return CupertinoIcons.wand_rays;
      case 'chart-square':
        return CupertinoIcons.chart_bar;
      case 'trophy':
        return CupertinoIcons.rosette;
      case 'double-arrow-right':
        return CupertinoIcons.chevron_forward;
      case 'double-arrow-left':
        return CupertinoIcons.chevron_back;
      default:
        return CupertinoIcons.question_circle;
    }
  }

  static IconData _material(String key) {
    switch (key) {
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'product':
        return Icons.inventory_2_outlined;
      case 'purchase':
        return Icons.credit_card_outlined;
      case 'sale':
        return Icons.shopping_cart_outlined;
      case 'manufacturing':
        return Icons.factory_outlined;
      case 'expense':
        return Icons.payments_outlined;
      case 'income':
        return Icons.savings_outlined;
      case 'quotation':
        return Icons.request_quote_outlined;
      case 'transfer':
        return Icons.swap_horiz;
      case 'return':
        return Icons.keyboard_return_outlined;
      case 'accounting':
        return Icons.calculate_outlined;
      case 'hrm':
        return Icons.groups_outlined;
      case 'people':
        return Icons.person_outline;
      case 'people-setting':
        return Icons.supervisor_account_outlined;
      case 'addons':
        return Icons.extension_outlined;
      case 'reports':
        return Icons.assessment_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'logout':
        return Icons.logout;
      case 'plus':
        return Icons.add;
      case 'bug':
        return Icons.bug_report;
      case 'delete':
        return Icons.delete_outline;
      case 'edit':
        return Icons.edit;
      case 'view':
        return Icons.visibility;
      case 'network':
        return Icons.network_check;
      case 'file-import':
        return Icons.file_upload_outlined;

      // Screen-level UI icons
      case 'appearance-system':
        return Icons.brightness_auto;
      case 'appearance-light':
        return Icons.light_mode;
      case 'appearance-dark':
        return Icons.dark_mode;
      case 'drawer':
        return Icons.menu;

      case 'status-success':
        return Icons.check_circle_rounded;
      case 'status-failed':
        return Icons.error_rounded;
      case 'status-warning':
        return Icons.warning_rounded;
      case 'status-pending':
        return Icons.pending_rounded;

      case 'time':
        return Icons.access_time_rounded;
      case 'speed':
        return Icons.speed_rounded;
      case 'close':
        return Icons.close_rounded;
      case 'upload':
        return Icons.upload_rounded;
      case 'download':
        return Icons.download_rounded;
      case 'http':
        return Icons.http_rounded;
      case 'check':
        return Icons.check_rounded;
      case 'copy':
        return Icons.copy_rounded;
      case 'data-object':
        return Icons.data_object_rounded;
      case 'inbox':
        return Icons.inbox_rounded;
      case 'error-outline':
        return Icons.error_outline_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;

      case 'chevron-right':
        return Icons.chevron_right;

      case 'error':
        return Icons.error_outline;
      case 'qr-scanner':
        return Icons.qr_code_scanner_rounded;

      case 'printer':
        return Icons.print_rounded;
      case 'check-circle':
        return Icons.check_circle_rounded;
      case 'close-circle':
        return Icons.cancel_rounded;
      case 'file-text':
        return Icons.description_rounded;
      case 'arrow-left':
        return Icons.arrow_back_rounded;

      case 'refresh':
        return Icons.refresh;
      case 'document-text':
        return Icons.description_outlined;
      case 'server':
        return Icons.dns_rounded;
      case 'key':
        return Icons.key_rounded;

      // Widget-level UI icons
      case 'info':
        return Icons.info_outline_rounded;
      case 'help':
        return Icons.help_outline_rounded;
      case 'plus-circle':
        return Icons.add_circle_outline_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'view-off':
        return Icons.visibility_off_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'more':
        return Icons.more_vert_rounded;
      case 'image-not-supported':
        return Icons.image_not_supported_rounded;
      case 'broken-image':
        return Icons.broken_image_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'link':
        return Icons.link_rounded;
      case 'fullscreen':
        return Icons.fullscreen_rounded;
      case 'chevron-left':
        return Icons.chevron_left_rounded;
      case 'arrow-right':
        return Icons.arrow_forward_rounded;
      case 'bluetooth-connected':
        return Icons.bluetooth_connected_rounded;

      // POS/payment related
      case 'money':
        return Icons.attach_money_rounded;
      case 'credit-card':
        return Icons.credit_card_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'gift-card':
        return Icons.card_giftcard_rounded;
      case 'account-balance':
        return Icons.account_balance_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'paypal':
        return Icons.paypal;
      case 'payment':
        return Icons.payment_rounded;
      case 'credit-score':
        return Icons.credit_score_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      case 'cancel':
        return Icons.cancel_rounded;
      case 'edit-document':
        return Icons.edit_document;
      case 'drafts':
        return Icons.drafts_rounded;
      case 'history':
        return Icons.history_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'image':
        return Icons.image_rounded;

      // Misc
      case 'magic-wand':
        return Icons.auto_fix_high_rounded;
      case 'chart-square':
        return Icons.bar_chart_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'double-arrow-right':
        return Icons.keyboard_double_arrow_right_rounded;
      case 'double-arrow-left':
        return Icons.keyboard_double_arrow_left_rounded;
      default:
        return Icons.help_outline;
    }
  }

  // Optional: a distinct fallback if you ever want HeroIcons.
  static Widget fallbackHero({Color? color, double? size}) {
    return HeroIcon(HeroIcons.questionMarkCircle, color: color, size: size);
  }
}