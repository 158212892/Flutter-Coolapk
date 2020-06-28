import 'dart:ui';

import 'package:coolapk_flutter/network/model/main_init.model.dart'
    as MainInitModel;
import 'package:coolapk_flutter/page/login/login.page.dart';
import 'package:coolapk_flutter/page/notification/notification.page.dart';
import 'package:coolapk_flutter/page/search/search.page.dart';
import 'package:coolapk_flutter/page/settings/settings.page.dart';
import 'package:coolapk_flutter/page/user_space/user_space.page.dart';
import 'package:coolapk_flutter/store/user.store.dart';
import 'package:coolapk_flutter/util/anim_page_route.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/**
 * 最垃圾的代码x2
 */

class HomePageDrawer extends StatefulWidget {
  final List<MainInitModel.MainInitModelData> tabConfigs;
  final Function(int, int) gotoTab;
  final Function(int, int) refreshTab;

  HomePageDrawer({Key key, this.tabConfigs, this.gotoTab, this.refreshTab})
      : super(key: key);

  @override
  HomePageDrawerState createState() => HomePageDrawerState();
}

class HomePageDrawerState extends State<HomePageDrawer>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _homePageSelected = 1;
  int _digitalPageSelected = 0;

  onGotoTab(int page, int tab) {
    bool hasChange = false;
    if (page == 0) {
      if (_homePageSelected != tab) hasChange = true;
      _homePageSelected = tab;
    } else {
      if (_digitalPageSelected != tab) hasChange = true;
      _digitalPageSelected = tab;
    }
    if (hasChange) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Drawer(
      elevation: 0,
      child: Material(
        color: Theme.of(context).cardColor,
        child: Stack(
          children: <Widget>[
            _buildTabControllPanel(context),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildUserCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(final BuildContext context) {
    return AppBar(
      elevation: 2,
      backgroundColor: Theme.of(context).cardColor,
      primary: false,
      title: Container(
        constraints: BoxConstraints(maxHeight: 36),
        child: TextField(
          autofocus: false,
          style: TextStyle(fontSize: 14),
          onSubmitted: (string) {
            Navigator.push(
                context,
                ScaleInRoute(
                    widget: SearchPage(
                  searchString: string,
                )));
          },
          decoration: InputDecoration(
            hintText: "搜索",
            fillColor: Theme.of(context).accentColor.withAlpha(30),
            contentPadding: const EdgeInsets.all(8),
            filled: true,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ),
    );
  }

  final double userCardHeight =
      64 + 32.toDouble(); // 54 usercard height + padding

  Widget _buildUserCard() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 4,
        child: Container(
          height: userCardHeight - 32, // - padding
          child: DrawerUserCard(),
        ),
      ),
    );
  }

  Widget _buildTabControllPanel(final BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _buildHeader(context),
        TabBar(
          controller: Provider.of<TabController>(context, listen: false),
          labelColor: Theme.of(context).textTheme.bodyText1.color,
          tabs: <Widget>[
            Tab(
              text: ("首页"),
            ),
            Tab(
              text: ("数码"),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            controller: Provider.of<TabController>(context, listen: false),
            children: widget.tabConfigs.map<Widget>((tabConfig) {
              return ListView(
                shrinkWrap: true,
                children: tabConfig.entities.map<Widget>((tabItem) {
                  final tabItemIndex = tabConfig.entities.indexOf(tabItem);
                  final selected = tabItemIndex ==
                      (tabConfig.entityId == 6390
                          ? _homePageSelected
                          : _digitalPageSelected);
                  return ListTile(
                    selected: selected,
                    dense: false,
                    title: Text(tabItem.title),
                    onTap: () {
                      widget.gotoTab(tabConfig.entityId, tabItemIndex);
                      setState(() {
                        if (tabConfig.entityId == 6390) {
                          _homePageSelected = tabItemIndex;
                        } else {
                          _digitalPageSelected = tabItemIndex;
                        }
                      });
                    },
                    trailing: !selected
                        ? const SizedBox()
                        : IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () {
                              widget.refreshTab(
                                  tabConfig.entityId, tabItemIndex);
                            },
                          ),
                    leading: tabItem.logo.length > 0 // 数码TAB没有logo.....
                        ? ExtendedImage.network(
                            tabItem.logo,
                            width: 24,
                            height: 24,
                            cache: true,
                          )
                        : null,
                  );
                }).toList()
                  ..add(Padding(
                    padding: EdgeInsets.only(bottom: userCardHeight),
                  )),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class DrawerUserCard extends StatefulWidget {
  DrawerUserCard({Key key}) : super(key: key);

  @override
  _DrawerUserCardState createState() => _DrawerUserCardState();
}

class _DrawerUserCardState extends State<DrawerUserCard> {
  @override
  Widget build(BuildContext context) {
    if (UserStore.of(context).loginInfo == null)
      return Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FlatButton(
            child: Text(
              "登录",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            textColor: Theme.of(context).accentColor,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                ScaleInRoute(widget: LoginPage()),
              );
            },
          ),
        ),
      );
    return InkWell(
      onTap: () {
        // TODO:
        if (Provider.of<UserStore>(context, listen: false).loginInfo?.uid !=
            null)
          UserSpacePage.entry(context,
              Provider.of<UserStore>(context, listen: false).loginInfo.uid);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ExtendedImage.network(
              UserStore.of(context).loginInfo.userAvatar + ".xs.jpg",
              cache: true,
              filterQuality: FilterQuality.low,
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
            const VerticalDivider(
              width: 8,
              color: Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      "${UserStore.of(context).userName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Divider(
                    height: 4,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildActionButton(context,
                          tooltip: "设置",
                          icon: Icons.settings,
                          onClick: () => Navigator.of(context)
                              .push(ScaleInRoute(widget: SettingPage()))),
                      _buildActionButton(context,
                          tooltip: "消息通知",
                          icon: Icons.mail_outline,
                          onClick: () =>
                              Navigator.of(context).push(ScaleInRoute(
                                widget: NotificationPage(),
                              ))),
                      _buildActionButton(context,
                          tooltip: "退出登录",
                          icon: Icons.exit_to_app,
                          onClick: _alertLogout),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _alertLogout() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("确定退出登录吗"),
              actions: [
                FlatButton(
                  child: Text("手滑点错"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: Text("确定"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ));
    if (ok == null) return;
    Provider.of<UserStore>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      ScaleInRoute(
        widget: LoginPage(),
      ),
    );
  }

  _buildActionButton(
    final BuildContext context, {
    String tooltip,
    IconData icon,
    Function onClick,
  }) {
    return IconButton(
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
      color: Theme.of(context).textTheme.bodyText1.color.withAlpha(120),
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 18,
      ),
      onPressed: onClick,
    );
  }
}
