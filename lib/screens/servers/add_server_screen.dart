
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
        title: Text(isEditing ? 'Edit Server' : 'Add Server'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Manual'),
                  Tab(text: 'Import'),
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
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 12),

          // 名称
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'My Server',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 地址
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'vpn.example.com',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            validator: (v) {
              if (v?.trim().isEmpty == true) return 'Address is required';
              if (!v!.trim().isValidAddress) return 'Invalid address';
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
                    labelText: 'TCP Port',
                    hintText: '443',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!v!.isValidPort) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _udpPortController,
                  decoration: const InputDecoration(
                    labelText: 'UDP Port',
                    hintText: '54321',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!v!.isValidPort) return 'Invalid';
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
              labelText: 'PSK (Pre-Shared Key)',
              hintText: 'Base64 encoded key',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePsk ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePsk = !_obscurePsk),
              ),
            ),
            obscureText: _obscurePsk,
            validator: (v) {
              if (v?.trim().isEmpty == true) return 'PSK is required';
              if (!v!.trim().isValidBase64) return 'Invalid Base64 format';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // 传输模式
          _buildSectionTitle('Transport Mode'),
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
                ? 'Faster, recommended for most cases'
                : 'More reliable in restrictive networks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          // TLS 设置
          _buildSectionTitle('TLS Settings'),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable TLS'),
            subtitle: const Text('Encrypt connection with TLS'),
            value: _tlsEnabled,
            onChanged: (v) => setState(() => _tlsEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_tlsEnabled) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _serverNameController,
              decoration: const InputDecoration(
                labelText: 'Server Name (SNI)',
                hintText: 'Leave empty to use address',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Skip Certificate Verification'),
              subtitle: const Text('Not recommended for production'),
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
                    'Advanced Settings',
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
            _buildSectionTitle('Forward Error Correction (FEC)'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable FEC'),
              subtitle: const Text('Recover lost packets automatically'),
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
                    label: Text('Adaptive'),
                  ),
                  ButtonSegment(
                    value: 'static',
                    label: Text('Static'),
                  ),
                ],
                selected: {_fecMode},
                onSelectionChanged: (v) => setState(() => _fecMode = v.first),
              ),
              const SizedBox(height: 8),
              Text(
                _fecMode == 'adaptive'
                    ? 'Automatically adjusts redundancy based on network conditions'
                    : 'Fixed redundancy level',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Mux 设置
            _buildSectionTitle('Multiplexing'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Multiplexing'),
              subtitle: const Text('Share single connection for multiple streams'),
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
              labelText: 'Share Link',
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
                  label: const Text('Paste'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importFromLink,
                  icon: const Icon(Icons.download),
                  label: const Text('Import'),
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
                  'Scan QR Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan a Phantom share QR code',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _scanQRCode,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open Camera'),
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
      context.showSnackBar('Please enter a share link', isError: true);
      return;
    }

    final server = Server.fromShareLink(link);
    if (server == null) {
      context.showSnackBar('Invalid share link format', isError: true);
      return;
    }

    context.read<ServersProvider>().addServer(server);
    Navigator.pop(context);
    context.showSnackBar('Server "${server.name}" added');
  }

  void _scanQRCode() {
    context.showSnackBar('QR scanning coming soon');
    // TODO: 实现 QR 扫描
  }

  void _save() {
    if (_tabController.index == 1) {
      // 导入模式，使用链接导入
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
      context.showSnackBar('Server updated');
    } else {
      servers.addServer(server);
      context.showSnackBar('Server added');
    }

    Navigator.pop(context);
  }
}

