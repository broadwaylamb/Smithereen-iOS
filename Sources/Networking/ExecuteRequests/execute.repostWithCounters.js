var repostID = API.wall.repost(
	{
		post_id: Args.post_id,
		message: Args.message,
		text_format: Args.text_format,
		attachments: Args.attachments,
		content_warning: Args.content_warning,
		guid: Args.guid,
	}
);
var op = API.wall.getById(
	{
		posts: Args.post_id,
		repost_history_depth: 1,
	}
)[0];
if (op.is_mastodon_style_repost) {
  op = op.repost_history[0];
}
var reposts_count = 0;
if (op.reposts) {
  reposts_count = op.reposts.count;
}
var likes_count = 0;
if (op.likes) {
  likes_count = op.likes.count;
}
return {
	post_id: repostID,
	reposts_count: reposts_count,
	likes_count: likes_count,
};
