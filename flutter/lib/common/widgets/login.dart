import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/hbbs/hbbs.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/user_model.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../common.dart';
import './dialog.dart';

const kOpSvgList = [
  'github',
  'gitlab',
  'google',
  'apple',
  'okta',
  'facebook',
  'azure',
  'auth0'
];

String _normalizeLoginErrorMessage(String cause) {
  const deviceLimitMsg = '已达登录设备上限，请联系管理员';
  final raw = cause.trim();
  if (raw.isEmpty) {
    return translate('Unknown Error');
  }
  final lower = raw.toLowerCase();
  if (raw == 'DeviceLoginLimitReached' ||
      lower.contains('device login limit reached') ||
      raw.contains(deviceLimitMsg)) {
    return deviceLimitMsg;
  }
  final translated = translate(raw);
  if (translated != raw) {
    return translated;
  }
  return raw;
}

class _LoginSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _LoginSectionCard({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = (theme.dividerColor).withOpacity(isDark ? 0.32 : 0.8);
    final iconBg = isDark
        ? MyTheme.accent.withOpacity(0.16)
        : MyTheme.accent.withOpacity(0.10);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: MyTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.72),
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LoginActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _LoginActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.85),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _IconOP extends StatelessWidget {
  final String op;
  final String? icon;
  final EdgeInsets margin;
  const _IconOP(
      {Key? key,
      required this.op,
      required this.icon,
      this.margin = const EdgeInsets.symmetric(horizontal: 4.0)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final svgFile =
        kOpSvgList.contains(op.toLowerCase()) ? op.toLowerCase() : 'default';
    return Container(
      margin: margin,
      child: icon == null
          ? SvgPicture.asset(
              'assets/auth-$svgFile.svg',
              width: 20,
            )
          : SvgPicture.string(
              icon!,
              width: 20,
            ),
    );
  }
}

class ButtonOP extends StatelessWidget {
  final String op;
  final RxString curOP;
  final String? icon;
  final Color primaryColor;
  final double height;
  final Function() onTap;

  const ButtonOP({
    Key? key,
    required this.op,
    required this.curOP,
    required this.icon,
    required this.primaryColor,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lowerOp = op.toLowerCase();
    final specialButtonLabel = {'wechat_open': '微信登录'}[lowerOp];
    final opLabel = {
          'github': 'GitHub',
          'gitlab': 'GitLab'
        }[lowerOp] ??
        toCapitalized(op);
    return Row(children: [
      Container(
        height: height,
        width: 200,
        child: Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: curOP.value.isEmpty || curOP.value == op
                  ? primaryColor
                  : Colors.grey,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
            onPressed: curOP.value.isEmpty || curOP.value == op ? onTap : null,
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: _IconOP(
                    op: op,
                    icon: icon,
                    margin: EdgeInsets.only(right: 5),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Center(
                        child: Text(specialButtonLabel ?? translate("Continue with {$opLabel}"))),
                  ),
                ),
              ],
            ))),
      ),
    ]);
  }
}

class ConfigOP {
  final String op;
  final String? icon;
  ConfigOP({required this.op, required this.icon});
}

class WidgetOP extends StatefulWidget {
  final ConfigOP config;
  final RxString curOP;
  final Function(Map<String, dynamic>) cbLogin;
  const WidgetOP({
    Key? key,
    required this.config,
    required this.curOP,
    required this.cbLogin,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WidgetOPState();
  }
}

class _WidgetOPState extends State<WidgetOP> {
  Timer? _updateTimer;
  String _stateMsg = '';
  String _failedMsg = '';
  String _url = '';

  @override
  void dispose() {
    super.dispose();
    _updateTimer?.cancel();
  }

  _beginQueryState() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateState();
    });
  }

  _updateState() {
    bind.mainAccountAuthResult().then((result) {
      if (result.isEmpty) {
        return;
      }
      final resultMap = jsonDecode(result);
      if (resultMap == null) {
        return;
      }
      final String stateMsg = resultMap['state_msg'];
      String failedMsg = resultMap['failed_msg'];
      final String? url = resultMap['url'];
      final bool urlLaunched = (resultMap['url_launched'] as bool?) ?? false;
      final authBody = resultMap['auth_body'];
      if (_stateMsg != stateMsg || _failedMsg != failedMsg) {
        if (_url.isEmpty && url != null && url.isNotEmpty) {
          if (!urlLaunched) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
          _url = url;
        }
        if (authBody != null) {
          _updateTimer?.cancel();
          widget.curOP.value = '';
          widget.cbLogin(authBody as Map<String, dynamic>);
        }

        setState(() {
          _stateMsg = stateMsg;
          _failedMsg = failedMsg;
          if (failedMsg.isNotEmpty) {
            widget.curOP.value = '';
            _updateTimer?.cancel();
          }
        });
      }
    });
  }

  _resetState() {
    _stateMsg = '';
    _failedMsg = '';
    _url = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ButtonOP(
          op: widget.config.op,
          curOP: widget.curOP,
          icon: widget.config.icon,
          primaryColor: str2color(widget.config.op, 0x7f),
          height: 36,
          onTap: () async {
            _resetState();
            widget.curOP.value = widget.config.op;
            await bind.mainAccountAuth(op: widget.config.op, rememberMe: true);
            _beginQueryState();
          },
        ),
        Obx(() {
          if (widget.curOP.isNotEmpty &&
              widget.curOP.value != widget.config.op) {
            _failedMsg = '';
          }
          return Offstage(
            offstage:
                _failedMsg.isEmpty && widget.curOP.value != widget.config.op,
            child: RichText(
              text: TextSpan(
                text: '$_stateMsg  ',
                style:
                    DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                children: <TextSpan>[
                  TextSpan(
                    text: _failedMsg,
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
        Obx(
          () => Offstage(
            offstage: widget.curOP.value != widget.config.op,
            child: const SizedBox(
              height: 5.0,
            ),
          ),
        ),
        Obx(
          () => Offstage(
            offstage: widget.curOP.value != widget.config.op,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 20),
              child: ElevatedButton(
                onPressed: () {
                  widget.curOP.value = '';
                  _updateTimer?.cancel();
                  _resetState();
                  bind.mainAccountAuthCancel();
                },
                child: Text(
                  translate('Cancel'),
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginWidgetOP extends StatelessWidget {
  final List<ConfigOP> ops;
  final RxString curOP;
  final Function(Map<String, dynamic>) cbLogin;

  LoginWidgetOP({
    Key? key,
    required this.ops,
    required this.curOP,
    required this.cbLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = ops
        .map((op) => [
              WidgetOP(
                config: op,
                curOP: curOP,
                cbLogin: cbLogin,
              ),
              const Divider(
                indent: 5,
                endIndent: 5,
              )
            ])
        .expand((i) => i)
        .toList();
    if (children.isNotEmpty) {
      children.removeLast();
    }
    return SingleChildScrollView(
        child: Container(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            )));
  }
}

class LoginWidgetUserPass extends StatelessWidget {
  final TextEditingController username;
  final TextEditingController pass;
  final String? usernameMsg;
  final String? passMsg;
  final bool isInProgress;
  final RxString curOP;
  final Function() onLogin;
  final FocusNode? userFocusNode;
  const LoginWidgetUserPass({
    Key? key,
    this.userFocusNode,
    required this.username,
    required this.pass,
    required this.usernameMsg,
    required this.passMsg,
    required this.isInProgress,
    required this.curOP,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8.0),
            DialogTextField(
                title: translate(DialogTextField.kUsernameTitle),
                controller: username,
                focusNode: userFocusNode,
                prefixIcon: DialogTextField.kUsernameIcon,
                errorText: usernameMsg),
            PasswordWidget(
              controller: pass,
              autoFocus: false,
              reRequestFocus: true,
              errorText: passMsg,
            ),
            // NOT use Offstage to wrap LinearProgressIndicator
            if (isInProgress) const LinearProgressIndicator(),
            const SizedBox(height: 12.0),
            FittedBox(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                height: 38,
                width: 200,
                child: Obx(() => ElevatedButton(
                      child: Text(
                        translate('Login'),
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed:
                          curOP.value.isEmpty || curOP.value == 'rustdesk'
                              ? () {
                                  onLogin();
                                }
                              : null,
                    )),
              ),
            ])),
          ],
        ));
  }
}


String _normalizeWechatFlowMessage(String cause, {required String fallback}) {
  final raw = cause.trim();
  if (raw.isEmpty) {
    return fallback;
  }
  final translated = translate(raw);
  if (translated != raw) {
    return translated;
  }
  return raw;
}

class _WechatDialogState {
  String sessionId = '';
  String qrUrl = '';
  String status = '';
  String statusText = '';
  String expiresAt = '';
  Map<String, dynamic>? authBody;

  void apply(WechatSessionPayload payload) {
    sessionId = payload.sessionId;
    qrUrl = payload.qrUrl;
    status = payload.status;
    statusText = payload.statusText;
    expiresAt = payload.expiresAt;
    authBody = payload.authBody;
  }
}

Widget _buildWechatQrBox(String qrUrl) {
  if (qrUrl.trim().isEmpty) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.qr_code_2, size: 72, color: Colors.grey),
          SizedBox(height: 8),
          Text('二维码区域占位', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  return Container(
    width: 180,
    height: 180,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.withOpacity(0.25)),
    ),
    padding: const EdgeInsets.all(8),
    child: QrImageView(
      backgroundColor: Colors.white,
      data: qrUrl,
      version: QrVersions.auto,
      size: 160,
      gapless: false,
    ),
  );
}

Future<bool?> _showWechatSessionDialog({
  required bool isBinding,
  required Future<WechatSessionPayload> Function() startSession,
  required Future<WechatSessionPayload> Function(String sessionId) pollSession,
  Future<bool> Function(Map<String, dynamic> authBody)? onSuccessAuthBody,
  Future<void> Function()? onCancel,
}) async {
  Timer? pollTimer;
  bool loading = false;
  String? errorText;
  final state = _WechatDialogState();

  Future<void> stopPolling() async {
    pollTimer?.cancel();
    pollTimer = null;
  }

  Future<void> startPolling(void Function(void Function()) setState, void Function([dynamic]) close) async {
    await stopPolling();
    if (state.sessionId.trim().isEmpty) {
      return;
    }
    pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final payload = await pollSession(state.sessionId);
        state.apply(payload);
        if (payload.authBody != null && onSuccessAuthBody != null) {
          final ok = await onSuccessAuthBody(payload.authBody!);
          if (ok) {
            await stopPolling();
            close(true);
            return;
          }
        }
        if (payload.status.toLowerCase() == 'success' && onSuccessAuthBody == null) {
          await stopPolling();
          close(true);
          return;
        }
        if (payload.status.toLowerCase() == 'failed' ||
            payload.status.toLowerCase() == 'expired' ||
            payload.status.toLowerCase() == 'cancelled' ||
            payload.status.toLowerCase() == 'error') {
          await stopPolling();
          setState(() {
            errorText = _normalizeWechatFlowMessage(
              payload.statusText,
              fallback: isBinding ? '微信绑定未完成，请刷新二维码后重试' : '微信登录未完成，请刷新二维码后重试',
            );
            loading = false;
          });
          return;
        }
        setState(() {
          errorText = null;
          loading = false;
        });
      } catch (e) {
        await stopPolling();
        setState(() {
          errorText = _normalizeWechatFlowMessage(
            e.toString(),
            fallback: isBinding ? '微信绑定状态查询失败，请稍后重试' : '微信登录状态查询失败，请稍后重试',
          );
          loading = false;
        });
      }
    });
  }

  Future<void> beginSession(void Function(void Function()) setState, void Function([dynamic]) close) async {
    await stopPolling();
    setState(() {
      loading = true;
      errorText = null;
      state.statusText = isBinding ? '正在获取微信绑定二维码...' : '正在获取微信登录二维码...';
    });
    try {
      final payload = await startSession();
      state.apply(payload);
      if (payload.authBody != null && onSuccessAuthBody != null) {
        final ok = await onSuccessAuthBody(payload.authBody!);
        if (ok) {
          setState(() => loading = false);
          close(true);
          return;
        }
      }
      if (payload.status.toLowerCase() == 'success' && onSuccessAuthBody == null) {
        setState(() => loading = false);
        close(true);
        return;
      }
      setState(() {
        loading = false;
        errorText = null;
      });
      await startPolling(setState, close);
    } catch (e) {
      setState(() {
        loading = false;
        errorText = _normalizeWechatFlowMessage(
          e.toString(),
          fallback: isBinding ? '管理员尚未完成微信登录配置' : '管理员尚未完成微信登录配置',
        );
      });
    }
  }

  final result = await gFFI.dialogManager.show<bool>((setState, close, context) {
    Future<void> onClose() async {
      await stopPolling();
      if (onCancel != null) {
        await onCancel();
      }
      close(false);
    }

    Future<void> onRefresh() async {
      await beginSession(setState, close);
    }

    Future.delayed(Duration.zero, () async {
      if (!loading && state.sessionId.isEmpty && errorText == null) {
        await beginSession(setState, close);
      }
    });

    return CustomAlertDialog(
      title: Text(isBinding ? '微信绑定' : '微信登录'),
      contentBoxConstraints: const BoxConstraints(maxWidth: 420),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBinding
                ? '当前账号尚未绑定微信，请使用微信扫码完成绑定后继续。'
                : '请使用微信扫码登录，手机确认后客户端会自动完成登录。',
            style: const TextStyle(fontSize: 13),
          ).marginOnly(bottom: 12),
          Center(child: _buildWechatQrBox(state.qrUrl)).marginOnly(bottom: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: errorText == null ? const Color(0xFFF4F8FF) : const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorText == null ? const Color(0xFFD5E4FF) : const Color(0xFFF3B7B7),
              ),
            ),
            child: Text(
              errorText ?? _normalizeWechatFlowMessage(
                state.statusText,
                fallback: isBinding ? '等待微信扫码绑定...' : '等待微信扫码登录...',
              ),
              style: TextStyle(
                fontSize: 13,
                color: errorText == null ? const Color(0xFF3B5B8C) : const Color(0xFFB83737),
                fontWeight: errorText == null ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ).marginOnly(bottom: 12),
          if (state.expiresAt.trim().isNotEmpty)
            Text('二维码有效期：${state.expiresAt}', style: const TextStyle(fontSize: 12, color: Colors.grey))
                .marginOnly(bottom: 4),
          if (loading) const LinearProgressIndicator(),
        ],
      ),
      actions: [
        dialogButton('刷新二维码', onPressed: onRefresh, isOutline: true),
        dialogButton(isBinding ? '退出登录' : '取消', onPressed: onClose),
      ],
      onCancel: onClose,
    );
  });
  await stopPolling();
  return result;
}

class WechatWidgetOP extends StatelessWidget {
  final ConfigOP config;
  final RxString curOP;
  final Future<void> Function() onTap;
  const WechatWidgetOP({
    Key? key,
    required this.config,
    required this.curOP,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ButtonOP(
          op: config.op,
          curOP: curOP,
          icon: config.icon,
          primaryColor: str2color(config.op, 0x7f),
          height: 36,
          onTap: () async {
            curOP.value = config.op;
            try {
              await onTap();
            } finally {
              curOP.value = '';
            }
          },
        ),
      ],
    );
  }
}


Future<bool> _handleWechatLoginSuccess(Map<String, dynamic> authBody) async {
  final resp = gFFI.userModel.getLoginResponseFromAuthBody(authBody);
  if (resp.access_token == null) {
    return false;
  }
  await bind.mainSetLocalOption(key: 'access_token', value: resp.access_token!);
  await bind.mainSetLocalOption(key: 'user_info', value: jsonEncode(resp.user ?? {}));
  return true;
}

Future<bool> _maybeRequireWechatBindingAfterLogin() async {
  try {
    final status = await gFFI.userModel.fetchWechatStatus(updateState: true);
    if (!status.enabled || !status.ready || status.bound) {
      return true;
    }
    final result = await _showWechatSessionDialog(
      isBinding: true,
      startSession: () => gFFI.userModel.startWechatBindSession(),
      pollSession: (sessionId) => gFFI.userModel.queryWechatBindSessionStatus(sessionId),
      onCancel: () async {
        await gFFI.userModel.logOut();
      },
    );
    return result == true;
  } catch (e) {
    debugPrint('_maybeRequireWechatBindingAfterLogin skipped: $e');
    return true;
  }
}

Future<bool?> loginByCodeDialog({
  required bool isEmail,
  required String initialAccount,
}) async {
  final account = TextEditingController(text: initialAccount);
  final code = TextEditingController();
  String? accountMsg;
  String? codeMsg;
  String statusText = isEmail ? '请输入账号或邮箱后发送邮箱验证码。' : '请输入账号或手机号后发送短信验证码。';
  bool sending = false;
  bool verifying = false;

  return gFFI.dialogManager.show<bool>((setState, close, context) {
    Future<void> sendCode() async {
      if (account.text.trim().isEmpty) {
        setState(() => accountMsg = isEmail ? '请输入账号或邮箱' : '请输入账号或手机号');
        return;
      }
      setState(() {
        sending = true;
        accountMsg = null;
        codeMsg = null;
      });
      try {
        final result = await gFFI.userModel.sendLoginCode(
          account: account.text,
          channel: isEmail ? 'email' : 'sms',
        );
        setState(() {
          statusText = (result['message'] ?? '').toString().trim();
          final masked = (result['masked_target'] ?? '').toString().trim();
          if (masked.isNotEmpty) {
            statusText = '$statusText ($masked)';
          }
        });
      } on RequestException catch (err) {
        setState(() => accountMsg = _normalizeLoginErrorMessage(err.cause));
      } catch (err) {
        setState(() => accountMsg = 'Unknown Error: $err');
      } finally {
        setState(() => sending = false);
      }
    }

    Future<void> submitLogin() async {
      if (account.text.trim().isEmpty) {
        setState(() => accountMsg = isEmail ? '请输入账号或邮箱' : '请输入账号或手机号');
        return;
      }
      if (code.text.trim().isEmpty) {
        setState(() => codeMsg = '请输入验证码');
        return;
      }
      setState(() {
        verifying = true;
        accountMsg = null;
        codeMsg = null;
      });
      try {
        final resp = await gFFI.userModel.loginByCode(
          account: account.text,
          channel: isEmail ? 'email' : 'sms',
          code: code.text,
        );
        if (resp.access_token != null) {
          await bind.mainSetLocalOption(
              key: 'access_token', value: resp.access_token!);
          await bind.mainSetLocalOption(
              key: 'user_info', value: jsonEncode(resp.user ?? {}));
          close(true);
          return;
        }
        setState(() => codeMsg = '登录失败，服务器未返回访问令牌');
      } on RequestException catch (err) {
        setState(() => codeMsg = _normalizeLoginErrorMessage(err.cause));
      } catch (err) {
        setState(() => codeMsg = 'Unknown Error: $err');
      } finally {
        setState(() => verifying = false);
      }
    }

    return CustomAlertDialog(
      title: Text(isEmail ? '邮箱验证码登录' : '手机验证码登录'),
      contentBoxConstraints: const BoxConstraints(maxWidth: 390),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.76),
                  ),
            ),
          ),
          _LoginSectionCard(
            icon: isEmail
                ? Icons.mark_email_read_outlined
                : Icons.sms_outlined,
            title: isEmail ? '邮箱验证码' : '短信验证码',
            subtitle: isEmail
                ? '填写账号或邮箱，发送验证码后直接登录。'
                : '填写账号或手机号，发送验证码后直接登录。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DialogTextField(
                  title: isEmail ? '账号 / 邮箱' : '账号 / 手机号',
                  controller: account,
                  errorText: accountMsg,
                ),
                DialogTextField(
                  title: '验证码',
                  controller: code,
                  errorText: codeMsg,
                ),
                if (sending || verifying) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
      actions: [
        dialogButton('发送验证码', onPressed: sending ? null : sendCode, isOutline: true),
        dialogButton('登录', onPressed: verifying ? null : submitLogin),
      ],
      onCancel: close,
      onSubmit: submitLogin,
    );
  });
}

const kAuthReqTypeOidc = 'oidc/';

// call this directly
Future<bool?> loginDialog() async {
  var username =
      TextEditingController(text: UserModel.getLocalUserInfo()?['name'] ?? '');
  var password = TextEditingController();
  final userFocusNode = FocusNode()..requestFocus();
  Timer(Duration(milliseconds: 100), () => userFocusNode..requestFocus());

  String? usernameMsg;
  String? passwordMsg;
  var isInProgress = false;
  final RxString curOP = ''.obs;
  // Track hover state for the close icon
  bool isCloseHovered = false;

  final loginOptions = [].obs;
  Future.delayed(Duration.zero, () async {
    loginOptions.value = await UserModel.queryOidcLoginOptions();
  });

  final res = await gFFI.dialogManager.show<bool>((setState, close, context) {
    username.addListener(() {
      if (usernameMsg != null) {
        setState(() => usernameMsg = null);
      }
    });

    password.addListener(() {
      if (passwordMsg != null) {
        setState(() => passwordMsg = null);
      }
    });

    onDialogCancel() {
      isInProgress = false;
      close(false);
    }

    Future<void> onWechatLogin() async {
      final result = await _showWechatSessionDialog(
        isBinding: false,
        startSession: () => gFFI.userModel.startWechatLoginSession(),
        pollSession: (sessionId) => gFFI.userModel.queryWechatLoginSessionStatus(sessionId),
        onSuccessAuthBody: _handleWechatLoginSuccess,
      );
      if (result == true) {
        close(true);
      }
    }

    Future<void> onEmailCodeLogin() async {
      final result = await loginByCodeDialog(
        isEmail: true,
        initialAccount: username.text.trim(),
      );
      if (result == true) {
        close(true);
      }
    }

    Future<void> onSmsCodeLogin() async {
      final result = await loginByCodeDialog(
        isEmail: false,
        initialAccount: username.text.trim(),
      );
      if (result == true) {
        close(true);
      }
    }

    handleLoginResponse(LoginResponse resp, bool storeIfAccessToken,
        void Function([dynamic])? close) async {
      switch (resp.type) {
        case HttpType.kAuthResTypeToken:
          if (resp.access_token != null) {
            if (storeIfAccessToken) {
              await bind.mainSetLocalOption(
                  key: 'access_token', value: resp.access_token!);
              await bind.mainSetLocalOption(
                  key: 'user_info', value: jsonEncode(resp.user ?? {}));
            }
            if (close != null) {
              close(true);
            }
            return;
          }
          break;
        case HttpType.kAuthResTypeEmailCheck:
          bool? isEmailVerification;
          if (resp.tfa_type == null ||
              resp.tfa_type == HttpType.kAuthResTypeEmailCheck) {
            isEmailVerification = true;
          } else if (resp.tfa_type == HttpType.kAuthResTypeTfaCheck) {
            isEmailVerification = false;
          } else {
            passwordMsg = "Failed, bad tfa type from server";
          }
          if (isEmailVerification != null) {
            if (isMobile) {
              if (close != null) close(null);
              verificationCodeDialog(
                  resp.user, resp.secret, isEmailVerification);
            } else {
              setState(() => isInProgress = false);
              // Workaround for web, close the dialog first, then show the verification code dialog.
              // Otherwise, the text field will keep selecting the text and we can't input the code.
              // Not sure why this happens.
              if (isWeb && close != null) close(null);
              final res = await verificationCodeDialog(
                  resp.user, resp.secret, isEmailVerification);
              if (res == true) {
                if (!isWeb && close != null) close(false);
                return;
              }
            }
          }
          break;
        default:
          passwordMsg = "Failed, bad response from server";
          break;
      }
    }

    onLogin() async {
      // validate
      if (username.text.isEmpty) {
        setState(() => usernameMsg = translate('Username missed'));
        return;
      }
      if (password.text.isEmpty) {
        setState(() => passwordMsg = translate('Password missed'));
        return;
      }
      curOP.value = 'rustdesk';
      setState(() => isInProgress = true);
      try {
        final resp = await gFFI.userModel.login(LoginRequest(
            username: username.text,
            password: password.text,
            id: await bind.mainGetMyId(),
            uuid: await bind.mainGetUuid(),
            autoLogin: true,
            type: HttpType.kAuthReqTypeAccount));
        await handleLoginResponse(resp, true, close);
      } on RequestException catch (err) {
        passwordMsg = _normalizeLoginErrorMessage(err.cause);
      } catch (err) {
        passwordMsg = "Unknown Error: $err";
      }
      curOP.value = '';
      setState(() => isInProgress = false);
    }

    thirdAuthWidget() => Obx(() {
          if (loginOptions.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              LoginWidgetOP(
                ops: loginOptions
                    .where((e) => (e['name'] ?? '') != 'wechat_open')
                    .map((e) => ConfigOP(op: e['name'], icon: e['icon']))
                    .toList(),
                curOP: curOP,
                cbLogin: (Map<String, dynamic> authBody) async {
                  LoginResponse? resp;
                  try {
                    resp = gFFI.userModel.getLoginResponseFromAuthBody(authBody);
                  } catch (e) {
                    debugPrint('Failed to parse oidc login body: "$authBody"');
                  }
                  if (resp != null) {
                    await handleLoginResponse(resp, false, close);
                  }
                },
              ),
              if (loginOptions.any((e) => (e['name'] ?? '') == 'wechat_open'))
                WechatWidgetOP(
                  config: ConfigOP(op: 'wechat_open', icon: null),
                  curOP: curOP,
                  onTap: onWechatLogin,
                ).marginOnly(top: 8),
            ],
          );
        });

    final title = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('Login'),
        ).marginOnly(top: MyTheme.dialogPadding),
        MouseRegion(
          onEnter: (_) => setState(() => isCloseHovered = true),
          onExit: (_) => setState(() => isCloseHovered = false),
          child: InkWell(
            child: Icon(
              Icons.close,
              size: 25,
              // No need to handle the branch of null.
              // Because we can ensure the color is not null when debug.
              color: isCloseHovered
                  ? Colors.white
                  : Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.color
                      ?.withOpacity(0.55),
            ),
            onTap: onDialogCancel,
            hoverColor: Colors.red,
            borderRadius: BorderRadius.circular(5),
          ),
        ).marginOnly(top: 10, right: 15),
      ],
    );
    final titlePadding = EdgeInsets.fromLTRB(MyTheme.dialogPadding, 0, 0, 0);

    return CustomAlertDialog(
      title: title,
      titlePadding: titlePadding,
      contentBoxConstraints: BoxConstraints(minWidth: 430, maxWidth: 460),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用 API 账号登录',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '保持简洁的原生登录体验，支持密码、邮箱验证码、手机验证码与微信登录。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.72),
                      ),
                ),
              ],
            ),
          ),
          _LoginSectionCard(
            icon: Icons.lock_outline_rounded,
            title: '账号密码',
            subtitle: '适合日常登录，布局保持贴近原版 RustDesk 的简洁输入风格。',
            child: LoginWidgetUserPass(
              username: username,
              pass: password,
              usernameMsg: usernameMsg,
              passMsg: passwordMsg,
              isInProgress: isInProgress,
              curOP: curOP,
              onLogin: onLogin,
              userFocusNode: userFocusNode,
            ),
          ),
          const SizedBox(height: 10),
          _LoginSectionCard(
            icon: Icons.verified_user_outlined,
            title: '快捷验证码登录',
            subtitle: '忘记密码时可直接发送验证码登录，邮件与短信入口分开展示，更容易理解。',
            child: Row(
              children: [
                Expanded(
                  child: _LoginActionButton(
                    icon: Icons.mark_email_read_outlined,
                    label: '邮箱验证码登录',
                    onPressed: onEmailCodeLogin,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LoginActionButton(
                    icon: Icons.sms_outlined,
                    label: '手机验证码登录',
                    onPressed: onSmsCodeLogin,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Obx(() => Offstage(
                offstage: loginOptions.isEmpty,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _LoginSectionCard(
                      icon: Icons.account_circle_outlined,
                      title: '微信与第三方登录',
                      subtitle: '仅在服务端已启用并配置完成时显示，避免默认状态下界面拥挤。',
                      child: thirdAuthWidget(),
                    ),
                  ],
                ),
              )),
        ],
      ),
      onCancel: onDialogCancel,
      onSubmit: onLogin,
    );
  });

  if (res == true) {
    final bindOk = await _maybeRequireWechatBindingAfterLogin();
    if (!bindOk) {
      return false;
    }
    await UserModel.updateOtherModels();
  }

  return res;
}

Future<bool?> verificationCodeDialog(
    UserPayload? user, String? secret, bool isEmailVerification) async {
  var autoLogin = true;
  var isInProgress = false;
  String? errorText;

  final code = TextEditingController();

  final res = await gFFI.dialogManager.show<bool>((setState, close, context) {
    void onVerify() async {
      setState(() => isInProgress = true);

      try {
        final resp = await gFFI.userModel.login(LoginRequest(
            verificationCode: code.text,
            tfaCode: isEmailVerification ? null : code.text,
            secret: secret,
            username: user?.name,
            id: await bind.mainGetMyId(),
            uuid: await bind.mainGetUuid(),
            autoLogin: autoLogin,
            type: HttpType.kAuthReqTypeEmailCode));

        switch (resp.type) {
          case HttpType.kAuthResTypeToken:
            if (resp.access_token != null) {
              await bind.mainSetLocalOption(
                  key: 'access_token', value: resp.access_token!);
              close(true);
              return;
            }
            break;
          default:
            errorText = "Failed, bad response from server";
            break;
        }
      } on RequestException catch (err) {
        errorText = _normalizeLoginErrorMessage(err.cause);
      } catch (err) {
        errorText = "Unknown Error: $err";
      }

      setState(() => isInProgress = false);
    }

    final codeField = isEmailVerification
        ? DialogEmailCodeField(
            controller: code,
            errorText: errorText,
            readyCallback: onVerify,
            onChanged: () => errorText = null,
          )
        : Dialog2FaField(
            controller: code,
            errorText: errorText,
            readyCallback: onVerify,
            onChanged: () => errorText = null,
          );

    getOnSubmit() => codeField.isReady ? onVerify : null;

    return CustomAlertDialog(
        title: Text(translate("Verification code")),
        contentBoxConstraints: BoxConstraints(maxWidth: 300),
        content: Column(
          children: [
            Offstage(
                offstage: !isEmailVerification || user?.email == null,
                child: TextField(
                  decoration: InputDecoration(
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
                  readOnly: true,
                  controller: TextEditingController(text: user?.email),
                ).workaroundFreezeLinuxMint()),
            isEmailVerification ? const SizedBox(height: 8) : const Offstage(),
            codeField,
            /*
            CheckboxListTile(
              contentPadding: const EdgeInsets.all(0),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Row(children: [
                Expanded(child: Text(translate("Trust this device")))
              ]),
              value: trustThisDevice,
              onChanged: (v) {
                if (v == null) return;
                setState(() => trustThisDevice = !trustThisDevice);
              },
            ),
            */
            // NOT use Offstage to wrap LinearProgressIndicator
            if (isInProgress) const LinearProgressIndicator(),
          ],
        ),
        onCancel: close,
        onSubmit: getOnSubmit(),
        actions: [
          dialogButton("Cancel", onPressed: close, isOutline: true),
          dialogButton("Verify", onPressed: getOnSubmit()),
        ]);
  });
  // For verification code, desktop update other models in login dialog, mobile need to close login dialog first,
  // otherwise the soft keyboard will jump out on each key press, so mobile update in verification code dialog.
  if (isMobile && res == true) {
    await UserModel.updateOtherModels();
  }

  return res;
}

void logOutConfirmDialog() {
  gFFI.dialogManager.show((setState, close, context) {
    submit() {
      close();
      gFFI.userModel.logOut();
    }

    return CustomAlertDialog(
      content: Text(translate("logout_tip")),
      actions: [
        dialogButton(translate("Cancel"), onPressed: close, isOutline: true),
        dialogButton(translate("OK"), onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}
