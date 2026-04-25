//
//  DatePickerHelper.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 25/04/26.
//

import UIKit
import ObjectiveC

/// Helper DatePicker untuk UITextField
class DatePickerHelper {

    // MARK: - Formatter

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Associated Object Key

    private static var pickerKey: UInt8 = 0

    // MARK: - Show Picker

    static func show(
        on viewController: UIViewController,
        textField: UITextField,
        defaultDate: Date = Date(),
        minDate: Date? = nil,
        onSelected: @escaping (Int64) -> Void
    ) {

        // Create Picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = defaultDate

        if let minDate = minDate {
            datePicker.minimumDate = minDate
        }

        // Toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let cancel = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: nil,
            action: nil
        )

        let flex = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: nil,
            action: nil
        )

        // Save picker data
        let pickerData = DatePickerData(
            textField: textField,
            datePicker: datePicker,
            callback: onSelected
        )

        objc_setAssociatedObject(
            textField,
            &pickerKey,
            pickerData,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        // Actions
        cancel.target = self
        cancel.action = #selector(cancelTapped(_:))

        done.target = self
        done.action = #selector(doneTapped(_:))

        toolbar.setItems([cancel, flex, done], animated: false)

        // Attach
        textField.inputView = datePicker
        textField.inputAccessoryView = toolbar

        // Refresh input
        textField.reloadInputViews()

        // Open picker
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
    }

    // MARK: - Done

    @objc private static func doneTapped(_ sender: UIBarButtonItem) {

        guard let textField = currentFirstResponder() as? UITextField,
              let pickerData = objc_getAssociatedObject(
                textField,
                &pickerKey
              ) as? DatePickerData else {
            return
        }

        let selectedDate = pickerData.datePicker.date

        // Update text
        textField.text = displayFormatter.string(from: selectedDate)

        // Millis
        let millis = Int64(selectedDate.timeIntervalSince1970 * 1000)

        // Close
        textField.resignFirstResponder()

        // Callback
        pickerData.callback(millis)

        // Cleanup
        objc_setAssociatedObject(
            textField,
            &pickerKey,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - Cancel

    @objc private static func cancelTapped(_ sender: UIBarButtonItem) {

        guard let textField = currentFirstResponder() as? UITextField else {
            return
        }

        textField.resignFirstResponder()

        objc_setAssociatedObject(
            textField,
            &pickerKey,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - Utilities

    static func dateToMillis(_ date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    static func millisToDate(_ millis: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
    }

    static func format(_ date: Date) -> String {
        return displayFormatter.string(from: date)
    }

    // MARK: - First Responder Finder

    private static func currentFirstResponder() -> UIResponder? {
        UIResponder.currentFirstResponder
    }
}

// MARK: - Data Holder

private class DatePickerData {

    let textField: UITextField
    let datePicker: UIDatePicker
    let callback: (Int64) -> Void

    init(
        textField: UITextField,
        datePicker: UIDatePicker,
        callback: @escaping (Int64) -> Void
    ) {
        self.textField = textField
        self.datePicker = datePicker
        self.callback = callback
    }
}

// MARK: - First Responder Helper

extension UIResponder {

    private static weak var _currentFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(
            #selector(findFirstResponder(_:)),
            to: nil,
            from: nil,
            for: nil
        )
        return _currentFirstResponder
    }

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}
