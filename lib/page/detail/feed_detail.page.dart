import 'dart:convert';

import 'package:coolapk_flutter/network/api/main.api.dart';
import 'package:coolapk_flutter/network/model/reply_data_list.model.dart';
import 'package:coolapk_flutter/page/collection_list/add_collect.sheet.dart';
import 'package:coolapk_flutter/page/topic/topic_detail.page.dart';
import 'package:coolapk_flutter/page/user_space/user_space.page.dart';
import 'package:coolapk_flutter/store/user.store.dart';
import 'package:coolapk_flutter/util/anim_page_route.dart';
import 'package:coolapk_flutter/util/show_qr_code.dart';
import 'package:coolapk_flutter/widget/feed_author_tag.dart';
import 'package:coolapk_flutter/page/image_box/image_box.page.dart';
import 'package:coolapk_flutter/util/image_url_size_parse.dart';
import 'package:coolapk_flutter/widget/common_error_widget.dart';
import 'package:coolapk_flutter/widget/html_text.dart';
import 'package:coolapk_flutter/widget/follow_btn.dart';
import 'package:coolapk_flutter/widget/item_adapter/items/feed_type/feed.item.dart';
import 'package:coolapk_flutter/widget/limited_container.dart';
import 'package:coolapk_flutter/widget/thumb_up_button.dart';
import 'package:coolapk_flutter/widget/to_login_snackbar.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/ball_pulse_footer.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_easyrefresh/phoenix_header.dart';
import 'package:toast/toast.dart';

part 'feed_reply_list.dart';

part 'feed_reply_item.dart';

part 'reply_input.sheet.dart';

part 'util.dart';

class FeedDetailPage extends StatefulWidget {
  final String url;
  final dynamic feedId;

  FeedDetailPage({Key key, this.url, this.feedId}) : super(key: key);

  @override
  _FeedDetailPageState createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> {
  Map<String, dynamic> data;

  String get url => widget.url;

  String get feedId =>
      widget.feedId ??
      (url.startsWith("/feed/") ? url.replaceAll("/feed/", "") : null);

  GlobalKey<_FeedReplyListState> _feedReplyListKey;

  Future<bool> fetchData() async {
    if (data != null) return true;
    if (feedId == null) throw Exception("FeedID获取失败");
    final resp = await MainApi.getFeedDetail(feedId);
    data = resp;
    return true;
  }

  @override
  void initState() {
    _feedReplyListKey = GlobalKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return FutureBuilder(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final child =
              width > 860 ? _buildDesktop(context) : FeedDetailMobile(data);
          return child;
        }
        if (snapshot.hasError) {
          return CommonErrorWidget(
            error: snapshot.error,
            onRetry: () {
              setState(() {});
            },
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text("动态"),
          ),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(final BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        data,
        onReplyDone: (data) {
          _feedReplyListKey.currentState.addReplyRow(data);
        },
      ),
      body: LimitedContainer(
        limiteType: LimiteType.TwoColumn,
        child: Row(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: _buildDetail(context, data),
              ),
            ),
            Expanded(
              child: FeedReplyList(
                feedId,
                key: _feedReplyListKey,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FeedDetailMobile extends StatefulWidget {
  final Map<String, dynamic> data;

  const FeedDetailMobile(this.data, {Key key}) : super(key: key);

  @override
  _FeedDetailMobileState createState() => _FeedDetailMobileState();
}

class _FeedDetailMobileState extends State<FeedDetailMobile> {
  GlobalKey<_FeedReplyListState> _feedReplyListKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.comment),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _buildReplyPage(context),
              ));
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, widget.data, sliver: true, mobileMode: true),
        ],
        body: CustomScrollView(
          slivers: <Widget>[
            SliverList(
              delegate:
                  SliverChildListDelegate(_buildDetail(context, widget.data)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPage(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("回复:"),
        actions: [
          FlatButton(
            child: Text(
              "写评论",
              style: TextStyle(
                color: Theme.of(context).primaryTextTheme.bodyText1.color,
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => ReplyInputBottomSheet(
                  targetId: widget.data["entityId"],
                  hintText: "楼主",
                  onReplyDone: _feedReplyListKey.currentState.addReplyRow,
                ),
              );
            },
          ),
        ],
      ),
      body: FeedReplyList(
        widget.data["entityId"],
        key: _feedReplyListKey,
      ),
    );
  }
}

Widget _buildAppBar(
  final BuildContext context,
  final Map<String, dynamic> data, {
  final Function(ReplyDataEntity) onReplyDone,
  final sliver = false,
  final bool mobileMode = false,
}) {
  final t = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse((data["lastupdate"]).toString()) * 1000)
      .toUtc();
  final collected = (data["userAction"]["collect"] ?? 0) == 0 ? false : true;
  final action = [
    ThumbUpButton(
      feedID: data["entityId"],
      initThumbNum: data["likenum"],
      inaccentColor: true,
    ),
    FlatButton(
      child: Text(
        "写评论",
        style: TextStyle(
          color: Theme.of(context).primaryTextTheme.bodyText1.color,
        ),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => ReplyInputBottomSheet(
            targetId: data["entityId"],
            hintText: "楼主",
            onReplyDone: onReplyDone,
          ),
        );
      },
    ),
    Builder(
      builder: (context) => FlatButton.icon(
        label: Text(collected ? "取消收藏" : "收藏动态"),
        textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
        icon: Icon(collected ? Icons.star : Icons.star_border),
        onPressed: () {
          if (UserStore.getUserUid(context) == null) {
            showToLoginSnackBar(context);
            return;
          }
          showModalBottomSheet(
              context: context,
              builder: (context) =>
                  AddCollectSheet(targetId: data["entityId"])).then(
            (value) {
              // value == true 收藏成功
              if (value == null) return;
            },
          );
        },
      ),
    ),
    Builder(builder: (context) {
      return FollowButton(
        uid: data["uid"],
        initIsFollow:
            (data["userAction"]["followAuthor"] ?? 0) == 0 ? false : true,
      );
    }),
  ];
  final tile = ListTile(
    contentPadding: const EdgeInsets.all(0),
    leading: ExtendedImage.network(
      data["userInfo"]["userSmallAvatar"] + ".xs.jpg",
      width: kToolbarHeight - 14,
      height: kToolbarHeight - 14,
      shape: BoxShape.circle,
    ),
    title: Text(
      data["username"],
      style: TextStyle(
        color: Theme.of(context).primaryTextTheme.bodyText1.color,
      ),
    ),
    subtitle: HtmlText(
      html:
          "${data["userInfo"]["verify_label"] ?? ""} ${t.year == DateTime.now().year ? "" : "${t.year}年"}${t.month}月${t.day}日${t.hour}:${t.minute} " +
              data["infoHtml"].toString() +
              " ${data["device_title"]} ",
      shrinkToFit: true,
      defaultTextStyle: TextStyle(
        color:
            Theme.of(context).primaryTextTheme.subtitle1.color.withAlpha(200),
      ),
    ),
    trailing: mobileMode
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: action,
          ),
  );
  final double titleSpacing = data != null ? 0 : null;
  final title = data == null ? Text("获取中...") : tile;
  return sliver
      ? SliverAppBar(
          titleSpacing: titleSpacing,
          title: title,
          snap: true,
          floating: true,
          actions: [
            action[1],
            PopupMenuButton(
              color: Theme.of(context).accentColor,
              itemBuilder: (context) {
                return action.map((e) => PopupMenuItem(child: e)).toList();
              },
            )
          ],
        )
      : AppBar(titleSpacing: titleSpacing, title: title);
}

List<Widget> _buildDetail(
    final BuildContext context, final Map<String, dynamic> data) {
  final pjson = jsonDecode(data["message_raw_output"]);
  final hasImage =
      data["picArr"].length > 0 && data["picArr"][0].toString().isNotEmpty;
  return <Widget>[
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: pjson == null
          ? HtmlText(
              html: data["message"],
              shrinkToFit: true,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: parseContent(context, pjson),
            ),
    ),
    Divider(indent: 16, endIndent: 16),
    hasImage
        ? FlatButton(
            child: Text(
              pjson != null ? "点我查看所有图片" : "点我查看更多图片",
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            onPressed: () => ImageBox.push(context, urls: data["picArr"]),
          )
        : const SizedBox(),
    pjson != null
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Center(
                child: buildIfImageBox(data, context, tapToImageBox: true)),
          ),
    Divider(indent: 16, endIndent: 16),
  ];
}

List<Widget> parseContent(final BuildContext context, dynamic json) {
  return json.map<Widget>((node) {
    switch (node["type"]) {
      case "text":
        return Container(
          width: double.infinity,
          child: HtmlText(
            html: node["message"].toString(),
            shrinkToFit: true,
            defaultTextStyle: Theme.of(context)
                .textTheme
                .bodyText1
                .copyWith(fontWeight: FontWeight.w600),
          ),
        );
      case "image":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Divider(
              color: Colors.transparent,
              height: 8,
            ),
            Material(
              child: InkWell(
                onTap: () {
                  ImageBox.push(context, urls: [node["url"]]);
                },
                child: Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height / 1.3),
                  child: ExtendedImage.network(
                    node["url"],
                    cache: true,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            node["description"].toString().isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                    child: Center(
                      child: Text(
                        node["description"],
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        );
      default:
        return Text(
          "不支持的Node: " + node.toString(),
          style: TextStyle(color: Colors.red),
        );
    }
  }).toList();
}
