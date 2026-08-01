class InvoiceData {
  Company? company;
  Sale? sale;
  Customer? customer;
  List<Item>? items;
  Totals? totals;
  List<Payment>? payments;
  String? footer;
  String? warehouseName;
  String? billerFooter;

  InvoiceData({
    this.company,
    this.sale,
    this.customer,
    this.items,
    this.totals,
    this.payments,
    this.footer,
    this.warehouseName,
    this.billerFooter,
  });

  InvoiceData.fromJson(Map<String, dynamic> json) {
    company =
        json['company'] != null ? Company.fromJson(json['company']) : null;
    sale = json['sale'] != null ? Sale.fromJson(json['sale']) : null;
    customer =
        json['customer'] != null ? Customer.fromJson(json['customer']) : null;
    if (json['items'] != null) {
      items = <Item>[];
      json['items'].forEach((v) {
        items!.add(Item.fromJson(v));
      });
    }
    totals = json['totals'] != null ? Totals.fromJson(json['totals']) : null;
    if (json['payments'] != null) {
      payments = <Payment>[];
      json['payments'].forEach((v) {
        payments!.add(Payment.fromJson(v));
      });
    }
    footer = json['footer'];
    warehouseName = json['warehouse_name'];
    billerFooter = json['biller_footer'];
  }
}

class Company {
  String? name;
  String? vat;
  String? address;
  String? phone;
  String? email;
  String? city;
  String? country;

  Company(
      {this.name,
      this.vat,
      this.address,
      this.phone,
      this.email,
      this.city,
      this.country});

  Company.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    vat = json['vat'];
    address = json['address'];
    phone = json['phone'];
    email = json['email'];
    city = json['city'];
    country = json['country'];
  }
}

class Sale {
  int? id;
  String? referenceNo;
  String? date;
  String? status;
  String? paymentStatus;
  String? currencyCode;
  String? qrCode;
  String? numberInWords;
  String? billBy;

  Sale(
      {this.id,
      this.referenceNo,
      this.date,
      this.status,
      this.paymentStatus,
      this.currencyCode,
      this.qrCode,
      this.numberInWords,
      this.billBy});

  Sale.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString());
    referenceNo = json['reference_no'];
    date = json['date'];
    status = json['status'];
    paymentStatus = json['payment_status']?.toString();
    currencyCode = json['currency_code'];
    qrCode = json['qr_code'];
    numberInWords = json['number_in_words'];
    billBy = json['bill_by'];
  }
}

class Customer {
  String? name;
  String? phone;
  String? address;
  String? vatNumber;

  Customer({this.name, this.phone, this.address, this.vatNumber});

  Customer.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    phone = json['phone'];
    address = json['address'];
    vatNumber = json['vat_number'];
  }
}

class Item {
  String? name;
  String? code;
  dynamic qty;
  String? unit;
  dynamic unitPrice;
  dynamic tax;
  dynamic discount;
  dynamic total;

  Item(
      {this.name,
      this.code,
      this.qty,
      this.unit,
      this.unitPrice,
      this.tax,
      this.discount,
      this.total});

  Item.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    code = json['code'];
    qty = json['qty'];
    unit = json['unit'];
    unitPrice = double.tryParse(json['unit_price'].toString()) ??
        double.tryParse(json['price'].toString());
    tax = json['tax'];
    discount = double.tryParse(json['discount'].toString());
    total = double.tryParse(json['total'].toString()) ??
        double.tryParse(json['subtotal'].toString());
  }
}

class Totals {
  dynamic totalQty;
  dynamic totalItem;
  dynamic subtotal;
  dynamic totalShipping;
  dynamic totalTax;
  dynamic totalDiscount;
  dynamic grandTotal;
  dynamic paidAmount;
  dynamic dueAmount;
  dynamic changeReturn;

  Totals(
      {this.totalQty,
      this.totalItem,
      this.subtotal,
      this.totalShipping,
      this.totalTax,
      this.totalDiscount,
      this.grandTotal,
      this.paidAmount,
      this.dueAmount,
      this.changeReturn});

  Totals.fromJson(Map<String, dynamic> json) {
    totalQty = double.tryParse(json['total_qty'].toString()) ??
        double.tryParse(json['total_item'].toString()) ??
        double.tryParse(json['total_items'].toString());
    totalItem = double.tryParse(json['total_item'].toString()) ??
        double.tryParse(json['total_items'].toString());
    subtotal = double.tryParse(json['subtotal'].toString());
    totalShipping = double.tryParse(json['total_shipping'].toString()) ??
        double.tryParse(json['shipping_cost'].toString());
    totalTax = double.tryParse(json['total_tax'].toString()) ??
        double.tryParse(json['order_tax'].toString());
    totalDiscount = double.tryParse(json['total_discount'].toString()) ??
        double.tryParse(json['order_discount'].toString());
    grandTotal = double.tryParse(json['grand_total'].toString());
    paidAmount = double.tryParse(json['paid_amount'].toString());
    dueAmount = double.tryParse(json['due_amount'].toString());
    changeReturn = double.tryParse(json['change_return'].toString());
  }
}

class Payment {
  String? date;
  String? method;
  dynamic amount;
  dynamic change;
  String? note;

  Payment({this.date, this.method, this.amount, this.change, this.note});

  Payment.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    method = json['method'];
    amount = double.tryParse(json['amount'].toString());
    change = double.tryParse(json['change'].toString());
    note = json['note'];
  }
}
