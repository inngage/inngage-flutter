// In-App Message v2 domain models, mirroring the `/v4/message/objectMessage`
// contract shared by all Inngage SDKs. Class names follow the Android SDK
// reference names used in the contract documentation.

/// Resolved action type for [InAppV2Action.type]. Raw values are normalized to
/// lowercase before mapping; unknown values fall back to [dismiss].
enum InAppV2ActionType {
  deepLink,
  weblink,
  inAppUrl,
  metadata,
  dismiss;

  static InAppV2ActionType parse(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'deeplink':
      case 'deep_link':
        return InAppV2ActionType.deepLink;
      case 'weblink':
        return InAppV2ActionType.weblink;
      case 'in_app_url':
      case 'inapp':
        return InAppV2ActionType.inAppUrl;
      case 'metadata':
        return InAppV2ActionType.metadata;
      default:
        return InAppV2ActionType.dismiss;
    }
  }
}

class InAppV2Action {
  final InAppV2ActionType type;
  final String url;
  final Map<String, String> metadata;

  const InAppV2Action({
    this.type = InAppV2ActionType.dismiss,
    this.url = '',
    this.metadata = const {},
  });

  factory InAppV2Action.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return InAppV2Action(
      type: InAppV2ActionType.parse(json['type'] as String?),
      url: json['url'] as String? ?? '',
      metadata: rawMetadata is Map
          ? rawMetadata
              .map((key, value) => MapEntry('$key', value?.toString() ?? ''))
          : const {},
    );
  }
}

class InAppV2ButtonStyle {
  final String backgroundColor;
  final String textColor;
  final String hoverColor;

  const InAppV2ButtonStyle({
    this.backgroundColor = '#000000',
    this.textColor = '#FFFFFF',
    this.hoverColor = '',
  });

  factory InAppV2ButtonStyle.fromJson(Map<String, dynamic> json) {
    return InAppV2ButtonStyle(
      backgroundColor: json['backgroundColor'] as String? ?? '#000000',
      textColor: json['textColor'] as String? ?? '#FFFFFF',
      hoverColor: json['hoverColor'] as String? ?? '',
    );
  }
}

class InAppV2Button {
  final String text;
  final InAppV2ButtonStyle style;
  final InAppV2Action? action;

  const InAppV2Button({
    this.text = '',
    this.style = const InAppV2ButtonStyle(),
    this.action,
  });

  factory InAppV2Button.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['style'];
    final rawAction = json['action'];
    return InAppV2Button(
      text: json['text'] as String? ?? '',
      style: rawStyle is Map<String, dynamic>
          ? InAppV2ButtonStyle.fromJson(rawStyle)
          : const InAppV2ButtonStyle(),
      action: rawAction is Map<String, dynamic>
          ? InAppV2Action.fromJson(rawAction)
          : null,
    );
  }
}

class InAppV2Actions {
  final InAppV2Action? backgroundClick;
  final List<InAppV2Button> buttons;

  const InAppV2Actions({this.backgroundClick, this.buttons = const []});

  factory InAppV2Actions.fromJson(Map<String, dynamic> json) {
    final rawBackgroundClick = json['backgroundClick'];
    final rawButtons = json['buttons'];
    return InAppV2Actions(
      backgroundClick: rawBackgroundClick is Map<String, dynamic>
          ? InAppV2Action.fromJson(rawBackgroundClick)
          : null,
      buttons: rawButtons is List
          ? rawButtons
              .whereType<Map<String, dynamic>>()
              .map(InAppV2Button.fromJson)
              .toList()
          : const [],
    );
  }
}

class InAppV2Content {
  final String title;
  final String body;

  const InAppV2Content({this.title = '', this.body = ''});

  factory InAppV2Content.fromJson(Map<String, dynamic> json) {
    return InAppV2Content(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class InAppV2CarouselItem {
  final String image;
  final String imageType;
  final InAppV2Content content;
  final InAppV2Actions actions;

  const InAppV2CarouselItem({
    this.image = '',
    this.imageType = 'fill',
    this.content = const InAppV2Content(),
    this.actions = const InAppV2Actions(),
  });

  factory InAppV2CarouselItem.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final rawActions = json['actions'];
    return InAppV2CarouselItem(
      image: json['image'] as String? ?? '',
      imageType: json['imageType'] as String? ?? 'fill',
      content: rawContent is Map<String, dynamic>
          ? InAppV2Content.fromJson(rawContent)
          : const InAppV2Content(),
      actions: rawActions is Map<String, dynamic>
          ? InAppV2Actions.fromJson(rawActions)
          : const InAppV2Actions(),
    );
  }

  bool get hasRenderableContent =>
      image.isNotEmpty || content.title.isNotEmpty || content.body.isNotEmpty;
}

class InAppV2Media {
  final bool enabled;
  final String position;
  final List<InAppV2CarouselItem> items;

  const InAppV2Media({
    this.enabled = false,
    this.position = 'TOP',
    this.items = const [],
  });

  /// The slide fields may come directly in `media` (production format) or
  /// nested in `media.carousel` (compatibility); each field falls back to the
  /// nested object when absent at the top level.
  factory InAppV2Media.fromJson(Map<String, dynamic> json) {
    final rawCarousel = json['carousel'];
    final carousel =
        rawCarousel is Map<String, dynamic> ? rawCarousel : const {};

    final rawItems = json['items'] ?? carousel['items'];
    return InAppV2Media(
      enabled:
          json['enabled'] as bool? ?? carousel['enabled'] as bool? ?? false,
      position: json['position'] as String? ??
          carousel['position'] as String? ??
          'TOP',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(InAppV2CarouselItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class InAppV2Style {
  final String position;
  final String backgroundColor;
  final String? backgroundImage;
  final String borderColor;
  final bool shadow;
  final String titleColor;
  final String bodyColor;

  const InAppV2Style({
    this.position = 'center',
    this.backgroundColor = '',
    this.backgroundImage,
    this.borderColor = '',
    this.shadow = false,
    this.titleColor = '#000000',
    this.bodyColor = '#000000',
  });

  factory InAppV2Style.fromJson(Map<String, dynamic> json) {
    return InAppV2Style(
      position: json['position'] as String? ?? 'center',
      backgroundColor: json['backgroundColor'] as String? ?? '',
      backgroundImage: json['backgroundImage'] as String?,
      borderColor: json['borderColor'] as String? ?? '',
      shadow: json['shadow'] as bool? ?? false,
      titleColor: json['titleColor'] as String? ?? '#000000',
      bodyColor: json['bodyColor'] as String? ?? '#000000',
    );
  }
}

class InAppMessageV2 {
  final bool enabled;
  final String type;
  final InAppV2Style style;
  final InAppV2Media media;

  const InAppMessageV2({
    this.enabled = true,
    this.type = 'Banner',
    this.style = const InAppV2Style(),
    this.media = const InAppV2Media(),
  });

  /// Resolves the response envelope (`inAppMessage` → `payload` → flat root)
  /// and applies the suppression rules. Returns `null` when there is no
  /// in-app message to display.
  static InAppMessageV2? fromResponse(Map<String, dynamic>? response) {
    if (response == null) return null;

    Map<String, dynamic> raw = response;
    final wrapped = response['inAppMessage'] ?? response['payload'];
    if (wrapped is Map<String, dynamic>) {
      raw = wrapped;
    }

    if (raw['enabled'] == false) return null;
    if (!raw.containsKey('media') && !raw.containsKey('type')) return null;

    return InAppMessageV2.fromJson(raw);
  }

  factory InAppMessageV2.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['style'];
    final rawMedia = json['media'];
    return InAppMessageV2(
      enabled: json['enabled'] as bool? ?? true,
      type: json['type'] as String? ?? 'Banner',
      style: rawStyle is Map<String, dynamic>
          ? InAppV2Style.fromJson(rawStyle)
          : const InAppV2Style(),
      media: rawMedia is Map<String, dynamic>
          ? InAppV2Media.fromJson(rawMedia)
          : const InAppV2Media(),
    );
  }

  /// Minimum validation before rendering: enabled, non-empty type, and at
  /// least one slide with image/title/body — or a style background image.
  bool get hasRenderableContent {
    if (!enabled || type.isEmpty) return false;
    final hasSlide = media.items.any((item) => item.hasRenderableContent);
    final hasBackgroundImage = (style.backgroundImage ?? '').isNotEmpty;
    return hasSlide || hasBackgroundImage;
  }
}
