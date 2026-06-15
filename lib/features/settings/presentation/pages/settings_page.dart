// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/features/auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSection(
              title: 'Cuenta',
              children: [
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Información Personal',
                  subtitle: user?.displayName ?? 'Usuario',
                  onTap: () => _showEditProfile(context),
                ),
                _buildSettingsTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: user?.email ?? '',
                  onTap: () {}, // Email is read-only
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualizar tu contraseña',
                  onTap: () => _showChangePassword(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSection(
              title: 'Preferencias',
              children: [
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Gestionar notificaciones push',
                  onTap: () => _showNotificationSettings(context),
                ),
                _buildSettingsTile(
                  icon: Icons.location_on,
                  title: 'Ubicación',
                  subtitle: 'Configurar permisos de ubicación',
                  onTap: () => _showLocationSettings(context),
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Idioma',
                  subtitle: 'Español',
                  onTap: () => _showLanguageSettings(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSection(
              title: 'Soporte',
              children: [
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Ayuda',
                  subtitle: 'Preguntas frecuentes',
                  onTap: () => _showHelp(context),
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacidad',
                  subtitle: 'Política de privacidad',
                  onTap: () => _showPrivacy(context),
                ),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSection(
              title: 'Acciones',
              children: [
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de tu cuenta',
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: () => _showLogoutConfirmation(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppTheme.greenDeep,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context) {
    // TODO: Navigate to edit profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text('Esta función estará disponible próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Notificaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Donaciones cercanas'),
              subtitle: const Text('Recibir alertas de donaciones cerca de ti'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Actualizaciones de donaciones'),
              subtitle: const Text('Notificar sobre cambios en tus donaciones'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Comunidad'),
              subtitle: const Text('Noticias y eventos de la comunidad'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Ubicación'),
        content: const Text('Para usar esta función, ve a la configuración de tu dispositivo y habilita los permisos de ubicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              leading: Radio<String>(
                value: 'es',
                groupValue: 'es',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: 'es',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Text('¿En qué podemos ayudarte? Contáctanos a support@feedthefuture.org'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'En Feed the Future, respetamos tu privacidad. '
            'Tus datos personales se utilizan únicamente para mejorar tu experiencia '
            'en la aplicación. No compartimos tu información con terceros sin tu consentimiento.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Feed the Future',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.volunteer_activism, size: 48),
      children: const [
        Text('Una aplicación para conectar donadores con personas que necesitan ayuda.'),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
