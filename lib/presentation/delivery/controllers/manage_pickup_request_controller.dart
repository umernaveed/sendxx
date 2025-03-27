import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:sendx/app/core/get_di.dart';
import 'package:sendx/app/core/routes/app_pages.dart';
import 'package:sendx/app/extensions/controller_ext.dart';
import 'package:sendx/app/util/flush_snackbar.dart';
import 'package:sendx/data/models/create_delivery_request/create_delivery_request.dart';
import 'package:sendx/data/models/lasco_mass_pay_invoice_request/lasco_mass_pay_invoice_request.dart';
import 'package:sendx/data/models/manage_pick_up_request_meta/area.dart';
import 'package:sendx/data/models/manage_pick_up_request_meta/day.dart';
import 'package:sendx/data/models/manage_pick_up_request_meta/time_slot.dart';
import 'package:sendx/data/models/user/user.dart';
import 'package:sendx/domain/repositories/local_repository.dart';
import 'package:sendx/domain/repositories/remote_repository.dart';
import 'package:sendx/presentation/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:sendx/presentation/delivery/controllers/delivery_controller.dart';
import 'package:sendx/presentation/delivery/views/delivery_request_confirmation.dart';
import 'package:sendx/presentation/delivery/views/manage_pickup_request.dart';

class ManagePickUpRequestController extends GetxController {
  final RemoteRepository _remoteRepository;
  final LocalRepository _localRepository;
  final DeliveryController _deliveryController;

  ManagePickUpRequestController({
    required RemoteRepository remoteRepository,
    required LocalRepository localRepository,
  })  : _remoteRepository = remoteRepository,
        _localRepository = localRepository,
        _deliveryController = find<DeliveryController>();

  final areas = <Area>[];
  final days = <Day>[];
  List<TimeSlot> timeSlots = [];
  TimeSlot? selected;
  int? get selectedSlotID => selected?.id;
  List<TimeSlot> disableSlots = [];
  var deliveryType = DeliveryType(name: '', typeID: 0);
  String coast = '0';
  User user = User.empty();
  final formKey = GlobalKey<FormBuilderState>();
  TextEditingController coastController = TextEditingController(text: '0');

  @override
  void onReady() {
    super.onReady();
    _fetchMeta();
  }

  @override
  void onClose() {
    coastController.dispose();
    super.onClose();
  }

  void onAreaChange(Area area) {
    coast = area.cost ?? '0';
    timeSlots = area.timeSlots ?? [];
    disableSlots.clear();
    for (var slot in area.timeSlots ?? <TimeSlot>[]) {
      if (slot.availableCount <= 0) {
        disableSlots.add(slot);
      }
    }
    coastController.text = coast;
    update(['manage_pickup_request']);
  }

  void onDayChange(Day? e) {
    if (e == null) return;

    final dayBasedSlots = <TimeSlot>[];

    for (final slot in timeSlots) {
      if (slot.dayId.toString() == e.dayId) {
        dayBasedSlots.add(slot);
      }
    }

    disableSlots =
        dayBasedSlots.where((slot) => slot.availableCount <= 0).toList();
    timeSlots = dayBasedSlots;
    update(['manage_pickup_request']);
  }

  void onDeloveryTypeChange(DeliveryType e) {
    deliveryType = e;
    update(['manage_pickup_request']);
  }

  Future<void> onSchedule() async {
    if (deliveryType.typeID == 1) {
      onRegularDelivery();
    } else {
      Get.bottomSheet(DeliveryRequestConfirmation());
      onPrePickUpDelivery();
    }
  }

  // void test() {
  //   formKey.currentState?.save();
  //   final isValid = formKey.currentState?.validate() ?? false;
  //   if (!isValid) return;
  //   final formData = formKey.currentState?.value ?? {};
  //   if (formData.isEmpty) return;
  //   final mapedRequest = CreateDeliveryRequest.fromMap(formData);
  //   print(mapedRequest.toString());
  // }

  Future<void> onRegularDelivery() async {
    bool isSuccess = false;
    String message = '';
    await asyncTask(() async {
      formKey.currentState?.save();
      final isValid = formKey.currentState?.validate() ?? false;
      if (!isValid) return;
      final formData = formKey.currentState?.value ?? {};
      final mapedRequest = CreateDeliveryRequest.fromMap(formData);
      final ids = _deliveryController.selectedItems
          .map((e) => e.trackingNo)
          .toList()
          .join(',');
      final request = mapedRequest.copyWith(
        noOfPackages: _deliveryController.selectedItems.length.toString(),
        packageTotal: _deliveryController.totalAmount.value.toString(),
        packageIds: ids,
      );
      final result = await _remoteRepository.createDeliveryRequest(request);
      isSuccess = result.status;
      message = result.message;
    });
    if (isSuccess) {
      _deliveryController.onRefresh();
      final bottomNavNestedID = find<BottomNavController>().bottomNavNestedID;
      Get.back(id: bottomNavNestedID);
      FlushSnackbar.showSnackBar(message);
    }
  }

  /// Will Need To update this function
  Future<void> onPrePickUpDelivery() async {
    bool isSuccess = false;
    String message = '';
    await asyncTask(() async {
      formKey.currentState?.save();
      final isValid = formKey.currentState?.validate() ?? false;
      if (!isValid) return;
      final formData = formKey.currentState?.value ?? {};
      final mapedRequest = CreateDeliveryRequest.fromMap(formData);
      final ids = _deliveryController.selectedItems
          .map((e) => e.trackingNo)
          .toList()
          .join(',');
      final request = mapedRequest.copyWith(
        noOfPackages: _deliveryController.selectedItems.length.toString(),
        packageTotal: _deliveryController.totalAmount.value.toString(),
        packageIds: ids,
      );
      final result = await _remoteRepository.createDeliveryRequest(request);
      isSuccess = result.status;
      message = result.message;
    });
    if (isSuccess) {
      _deliveryController.onRefresh();
      final bottomNavNestedID = find<BottomNavController>().bottomNavNestedID;
      Get.back(id: bottomNavNestedID);
      FlushSnackbar.showSnackBar(message);
    }
  }

  Future<void> startPayment({
    required String packageIDs,
    required String invoiceIDs,
    required String balance,
  }) async {
    var paymentResponse = -1;
    await asyncTask(() async {
      final validBalance = balance.replaceAll('JMD', '').replaceAll(',', '');
      final amount = num.tryParse(validBalance) ?? 0;

      final result = await asyncTaskWithResult<String>(() async {
        final request = LascoMassPayInvoiceRequest(
            invoiceIds: invoiceIDs,
            packageIds: packageIDs,
            invoiceTotal: amount.toString());
        final response = await _remoteRepository.lascoMassPayInvoice(request);
        return response.data;
      });
      if (result?.isNotEmpty ?? false) {
        final response = await Get.toNamed(
          AppPages.paymentWebView,
          arguments: {
            'url': result,
          },
        );
        if (response == -1) {
          paymentResponse = -1;
        } else if (response == 1) {
          paymentResponse = 1;
        }
      }
    });
    if (paymentResponse == -1) {
      FlushSnackbar.showSnackBar('Payment has been canceled', isError: true);
    } else if (paymentResponse == 1) {
      onPrePickUpDelivery();
      FlushSnackbar.showSnackBar('Payment has been done', isError: false);
    }
  }

  Future<void> _fetchMeta() async {
    await asyncTask(() async {
      final result = await _remoteRepository.getManagePickUpRequestMeta();
      final a = result.data.areas ?? [];
      final d = result.data.days ?? [];
      areas.addAll(a);
      days.addAll(d);
    }).then((value) {
      update(['manage_pickup_request']);
    });
  }

  void onTimeSlotChange(TimeSlot slot) {
    selected = slot;
  }

  User getInstantUser() {
    final r = _localRepository.getInstantUser();
    return r;
  }
}
