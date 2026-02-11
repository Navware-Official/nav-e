import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/utils/snackbar_helper.dart';
import 'package:nav_e/core/widgets/state_views.dart';
import 'package:nav_e/core/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/device_management/widgets/device_card_widget.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DevicesBloc>().add(LoadDevices());
    BlocProvider.of<BluetoothBloc>(context).add(InitiateConnectionCheck());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pushReplacement('/'),
        ),
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DevicesBloc>().add(LoadDevices()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BackButtonListener(
        onBackButtonPressed: () async {
          GoRouter.of(context).go('/');
          return true;
        },
        child: BlocConsumer<DevicesBloc, DevicesState>(
          listener: (context, state) {
            if (state is DeviceOperationSuccess) {
              showAppSnackBar(context, state.message);
              context.read<DevicesBloc>().add(LoadDevices());
            }
          },
          builder: (context, state) {
            if (state is DeviceLoadInProgress) {
              return const AppLoadingState(message: 'Loading devices...');
            }

            if (state is DeviceOperationFailure) {
              return AppErrorState(
                title: 'Error Loading Devices',
                message: state.message,
                onRetry: () => context.read<DevicesBloc>().add(LoadDevices()),
              );
            }

            if (state is DeviceLoadSuccess) {
              if (state.devices.isEmpty) {
                return AppEmptyState(
                  icon: Icons.bluetooth_disabled,
                  title: 'No Devices Yet',
                  subtitle:
                      'Add a Bluetooth device to get started.\nYou can connect to watches, phones, or other devices.',
                  actionLabel: 'Add Your First Device',
                  onAction: () => context.pushNamed('addDevice'),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: state.devices.length,
                      itemBuilder: (context, index) {
                        final device = state.devices[index];
                        return DeviceCard(device: device);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed('addDevice'),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add New Device'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return AppErrorState(
              title: 'Something went wrong',
              message: 'An unexpected error occurred.',
              onRetry: () => context.read<DevicesBloc>().add(LoadDevices()),
            );
          },
        ),
      ),
    );
  }
}
