// ============================================================
// lib/screens/servers/add_server_screen.dart (中文版)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/server.dart';
import '../../providers/servers_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../core/utils/extensions.dart';

class AddServerScreen extends StatefulWidget {
  final Server? server;

  const AddServerScreen({super.key, this.server});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _tcpPortController = TextEditingController(text: '443');
  final _udpPortController = TextEditingController(text: '54321');
  final _pskController = TextEditingController();
  final _linkController = TextEditingController();
  final _serverNameController = TextEditingController();

  // 配置状态
  bool _tlsEnabled = true;
  bool _tlsSkipVerify = false;
  String _mode = 'udp';
  bool _fecEnabled = true;
  String _fecMode = 'adaptive';
  bool _muxEnabled = true;

  bool _showAdvanced = false;
  bool _obscurePsk = true;

  bool get isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 加载默认设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (!isEditing) {
        _fecEnabled = settings.defaultFecEnabled;
        _fecMode = settings.defaultFecMode;
        _muxEnabled = settings.defaultMuxEnabled;
      }
    });

    if (isEditing) {
      final server = widget.server!;
      _nameController.text = server.name;
      _addressController.text = server.address;
      _tcpPortController.text = server.tcpPort.toString();
      _udpPortController.text = server.udpPort.toString();
      _pskController.text = server.psk;
      _tlsEnabled = server.tls.enabled;
      _tlsSkipVerify = server.tls.skipVerify;
      _serverNameController.text = server.tls.serverName ?? '';
      _mode = server.mode;
      _fecEnabled = server.fec.enabled;
      _fecMode = server.fec.mode;
      _muxEnabled = server.mux.enabled;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _tcpPortController.dispose();
    _udpPortController.dispose();
    _pskController.dispose();
    _linkController.dispose();
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑服务器' : '添加服务器'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '手动配置'),
                  Tab(text: '导入'),
                ],
              ),
      ),
      body: isEditing
          ? _buildManualForm()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildManualForm(),
                _buildImportForm(),
              ],
            ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 基本信息部分
          _buildSectionTitle('基本信息'),
          const SizedBox(height: 12),

          // 名称
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '我的服务器',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 地址
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '地址',
              hintText: 'vpn.example.com',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            validator: (v) {
              if (v?.trim().isEmpty == true) return '请输入地址';
              if (!v!.trim().isValidAddress) return '地址格式无效';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 端口（TCP 和 UDP）
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tcpPortController,
                  decoration: const InputDecoration(
                    labelText: 'TCP 端口',
                    hintText: '443',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v?.isEmpty == true) return '必填';
                    if (!v!.isValidPort) return '无效';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _udpPortController,
                  decoration: const InputDecoration(
                    labelText: 'UDP 端口',
                    hintText: '54321',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v?.isEmpty == true) return '必填';
                    if (!v!.isValidPort) return '无效';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PSK
          TextFormField(
            controller: _pskController,
            decoration: InputDecoration(
              labelText: 'PSK (预共享密钥)',
              hintText: 'Base64 编码的密钥',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePsk ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePsk = !_obscurePsk),
              ),
            ),
            obscureText: _obscurePsk,
            validator: (v) {
              if (v?.trim().isEmpty == true) return '请输入 PSK';
              if (!v!.trim().isValidBase64) return 'Base64 格式无效';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 传输模式
          _buildSectionTitle('传输模式'),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'udp',
                label: Text('UDP'),
                icon: Icon(Icons.speed),
              ),
              ButtonSegment(
                value: 'tcp',
                label: Text('TCP'),
                icon: Icon(Icons.lock_outline),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == 'udp'
                ? '速度更快，适用于大多数场景'
                : '更可靠，适用于受限网络环境',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          // TLS 设置
          _buildSectionTitle('TLS 设置'),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('启用 TLS'),
            subtitle: const Text('使用 TLS 加密连接'),
            value: _tlsEnabled,
            onChanged: (v) => setState(() => _tlsEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_tlsEnabled) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _serverNameController,
              decoration: const InputDecoration(
                labelText: '服务器名称 (SNI)',
                hintText: '留空则使用地址',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('跳过证书验证'),
              subtitle: const Text('不建议在生产环境使用'),
              value: _tlsSkipVerify,
              onChanged: (v) => setState(() => _tlsSkipVerify = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: 16),

          // 高级设置折叠
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '高级设置',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 高级设置内容
          if (_showAdvanced) ...[
            const SizedBox(height: 16),

            // FEC 设置
            _buildSectionTitle('前向纠错 (FEC)'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('启用 FEC'),
              subtitle: const Text('自动恢复丢失的数据包'),
              value: _fecEnabled,
              onChanged: (v) => setState(() => _fecEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_fecEnabled) ...[
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'adaptive',
                    label: Text('自适应'),
                  ),
                  ButtonSegment(
                    value: 'static',
                    label: Text('静态'),
                  ),
                ],
                selected: {_fecMode},
                onSelectionChanged: (v) => setState(() => _fecMode = v.first),
              ),
              const SizedBox(height: 8),
              Text(
                _fecMode == 'adaptive'
                    ? '根据网络状况自动调整冗余度'
                    : '固定冗余等级',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Mux 设置
            _buildSectionTitle('多路复用'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('启用多路复用'),
              subtitle: const Text('单连接承载多个数据流'),
              value: _muxEnabled,
              onChanged: (v) => setState(() => _muxEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildImportForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 分享链接输入
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: '分享链接',
              hintText: 'phantom://...',
              prefixIcon: Icon(Icons.link),
            ),
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('粘贴'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importFromLink,
                  icon: const Icon(Icons.download),
                  label: const Text('导入'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // QR 扫描
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '扫描二维码',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '扫描 Phantom 分享二维码',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _scanQRCode,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('打开相机'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _linkController.text = data!.text!;
    }
  }

  void _importFromLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      context.showSnackBar('请输入分享链接', isError: true);
      return;
    }

    final server = Server.fromShareLink(link);
    if (server == null) {
      context.showSnackBar('分享链接格式无效', isError: true);
      return;
    }

    context.read<ServersProvider>().addServer(server);
    Navigator.pop(context);
    context.showSnackBar('服务器 "${server.name}" 已添加');
  }

  void _scanQRCode() {
    context.showSnackBar('二维码扫描功能即将推出');
  }

  void _save() {
    if (_tabController.index == 1) {
      _importFromLink();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final server = Server(
      id: widget.server?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      tcpPort: int.parse(_tcpPortController.text),
      udpPort: int.parse(_udpPortController.text),
      psk: _pskController.text.trim(),
      mode: _mode,
      tls: TLSConfig(
        enabled: _tlsEnabled,
        serverName: _serverNameController.text.trim().isEmpty
            ? null
            : _serverNameController.text.trim(),
        skipVerify: _tlsSkipVerify,
      ),
      fec: FECConfig(
        enabled: _fecEnabled,
        mode: _fecMode,
      ),
      mux: MuxConfig(
        enabled: _muxEnabled,
      ),
    );

    final servers = context.read<ServersProvider>();
    if (isEditing) {
      servers.updateServer(server);
      context.showSnackBar('服务器已更新');
    } else {
      servers.addServer(server);
      context.showSnackBar('服务器已添加');
    }

    Navigator.pop(context);
  }
}
