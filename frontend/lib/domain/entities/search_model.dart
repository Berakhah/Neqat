class ShowSearchModel {
  final String? author;
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? content;
  final String? type; // 'news' or 'telegram'
  final String? channelName; // For Telegram messages
  final String? senderId; // For Telegram messages
  final String? date; // For Telegram messages

  ShowSearchModel({
    this.author,
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.content,
    this.type = 'news', // Default to news
    this.channelName,
    this.senderId,
    this.date,
  });
}
