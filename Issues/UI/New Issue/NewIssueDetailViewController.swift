//
//  NewIssueDetailViewController.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import SeeClickFix

protocol UIAnswer {
    func anyAnswer() throws -> AnyAnswer
}

class NewIssueDetailViewController : UIViewController {
    struct NewIssueAnswer<AnswerType, UIInfoType> : UIAnswer where AnswerType : HTTPEncodedValue, AnswerType : Encodable {
        var answer: Answer<AnswerType>
        var uiInfo: UIInfoType
        init(answer: Answer<AnswerType>, uiInfo: UIInfoType) {
            self.answer = answer
            self.uiInfo = uiInfo
        }
        func anyAnswer() throws -> AnyAnswer {
            return answer
        }
    }
    struct MapUIInfo {
        var locked: Bool
    }
    private enum CellIdentifier : String {
        case location
        case textField
        case textView
        case imageCapture
        case imageDisplay
        case picker
        case label
        case datePicker
    }
    private lazy var fetchResultsControllerCollectionViewAdapter: FRCCollectionView<Question> = {
        guard let identifier = self.reportTypeIdentifier else {
            preconditionFailure()
        }
        let fetchRequest: NSFetchRequest<Question>
        do {
            fetchRequest = try Question.fetchRequest()
        } catch {
            preconditionFailure()
        }
        fetchRequest.predicate = NSPredicate(format: "reportType.id == %@", NSNumber(value: identifier))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let moc = DataStore.shared.reader
        var frc = FRC(fetchRequest: fetchRequest, managedObjectContext: moc, cacheName: "ReportDetailCache.\(identifier)")
        return FRCCollectionView(fetchedResultsController: frc) { [weak self] () -> UICollectionView? in
            return self?.collectionView
        }
    }()
    private var fetchedResultsController: FRC<Question> {
        get {
            return self.fetchResultsControllerCollectionViewAdapter.fetchedResultsController
        }
    }
    private var answers = [String : UIAnswer]() {
        didSet {
            scheduleSaveAnswers()
        }
    }
    private func scheduleSaveAnswers() {
        
    }
    // Hang this off NewIssueLocationCell
    private var imagePicker: ImagePicker?
    var reportTypeIdentifier: Int?
    @IBOutlet var collectionView: UICollectionView?
    var location = LocationAdapter()
    private func registerCell(name: String, identifier: CellIdentifier) {
        collectionView?.register(UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: identifier.rawValue)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(name: NewIssueLocationCell.nibName, identifier: .location)
        registerCell(name: NewIssueBodyLabelCell.nibName, identifier: .label)
        registerCell(name: NewIssueTextFieldCell.nibName, identifier: .textField)
        registerCell(name: NewIssueTextViewCell.nibName, identifier: .textView)
        registerCell(name: NewIssueCaptureImageViewCell.nibName, identifier: .imageCapture)
        registerCell(name: NewIssueDisplayImageViewCell.nibName, identifier: .imageDisplay)
        registerCell(name: NewIssuePickerCell.nibName, identifier: .picker)
        registerCell(name: NewIssueDatePickerCell.nibName, identifier: .datePicker)
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("NewIssueDetailViewController.Submit", comment: ""), style: .plain, target: self, action: #selector(submit))
        do {
            try fetchedResultsController.performFetch()
        } catch {
            self.navigationController?.popViewController(animated: true)
        }
    }
    @IBAction func submit(sender: Any?) {
        do {
            Coordinator.shared.submitReport(answers: try self.answers.values.map() { return try $0.anyAnswer() }).then(on: CFRunLoop.main, { _ in
                
            }).catch(on: CFRunLoop.main) { _ in
                
            }
        } catch {
            
        }
    }
    enum NewIssueDetailViewControllerError : Error {
        case indexPathNotFound
    }
    private func indexPath(format: Question.Format) throws -> IndexPath {
        var iterator = self.fetchedResultsController.iterator()
        while let (indexPath, question) = iterator.next() {
            do {
                switch try question.format() {
                case format:
                    return indexPath
                default:
                    continue
                }
            } catch {
                continue
            }
        }
        throw NewIssueDetailViewControllerError.indexPathNotFound
    }
    private func indexPathForMap() throws -> IndexPath {
        return try indexPath(format: .location)
    }
    private func indexPathForImage() throws -> IndexPath {
        return try indexPath(format: .image)
    }
    private func updateMapAnswer(key: String, center: CLLocationCoordinate2D, locked: Bool) {
        answers[key] = NewIssueAnswer(answer: Answer(key: key, value: center), uiInfo: MapUIInfo(locked: locked))
    }
    private func updateTextFieldAnswer(key: String, text: String?) {
        if let value = text, value.count > 0 {
            answers[key] = NewIssueAnswer(answer: Answer(key: key, value: value), uiInfo: ())
        } else {
            answers.removeValue(forKey: key)
        }
    }
    private func updateImageAnswer(answer: Answer<URL>) {
        answers[answer.key] = NewIssueAnswer(answer: answer, uiInfo: ())
        if let collectionView = collectionView, let indexPath = try? indexPathForImage() {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension NewIssueDetailViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let newIssueCell = cell as? NewIssueCell else {
            return
        }
        newIssueCell.willDisplay()
    }
}

extension NewIssueDetailViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        do {
            return try fetchedResultsController.count(section: section)
        } catch {
            return 0
        }
    }
    enum CollectionViewError : Error {
        case unexpectedCellType
    }
    private func dq<T>(identifier: CellIdentifier, indexPath: IndexPath) throws -> T where T : NewIssueCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: identifier.rawValue, for: indexPath) as? T else {
            throw CollectionViewError.unexpectedCellType
        }
        return cell
    }
    private func locationCell(question: Question, indexPath: IndexPath) throws -> NewIssueLocationCell {
        let cell: NewIssueLocationCell = try dq(identifier: .location, indexPath: indexPath)
        guard let key = question.key else {
            cell.mapCenterDidChange = nil
            return cell
        }
        cell.mapCenterDidChange = { [weak self] cell, center in
            self?.updateMapAnswer(key: key, center: center, locked: cell.locked)
        }
        if let uiAnswer = self.answers[key] as? NewIssueAnswer<CLLocationCoordinate2D, MapUIInfo> {
            cell.locked = uiAnswer.uiInfo.locked
            cell.shouldZoomToCoordinate = false
            cell.zoomToCoordinate(coordinate: uiAnswer.answer.value, animated: false)
        }
        return cell
    }
    private func imageDisplayCell(question: Question, indexPath: IndexPath, answer: Answer<URL>) throws -> NewIssueDisplayImageViewCell {
        let cell: NewIssueDisplayImageViewCell = try dq(identifier: .imageDisplay, indexPath: indexPath)
        cell.url = answer.value
        cell.delegate = self
        return cell
    }
    private func imageCaptureCell(question: Question, indexPath: IndexPath, key: String) throws -> NewIssueCaptureImageViewCell {
        let cell: NewIssueCaptureImageViewCell = try dq(identifier: .imageCapture, indexPath: indexPath)
        cell.addImageButton?.setTitle(NSLocalizedString("NewIssueDetailViewController.AddMedia", comment: ""), for: .normal)
        imagePicker = ImagePicker(key: key)
        imagePicker?.present = { [weak self] viewController, animated, completion in
            self?.present(viewController, animated: animated, completion: completion)
        }
        imagePicker?.result = { [weak self] answer in
            self?.updateImageAnswer(answer: answer)
        }
        cell.capture = {
            self.imagePicker?.showMediaActionSheet()
        }
        return cell
    }
    private func imageCell(question: Question, indexPath: IndexPath) throws -> NewIssueCell {
        let question = fetchedResultsController.object(at: indexPath)
        guard let key = question.key else {
            preconditionFailure() // TODO throw
        }
        if let uiAnswer = answers[key] as? NewIssueAnswer<URL, Any> {
            return try imageDisplayCell(question: question, indexPath: indexPath, answer: uiAnswer.answer)
        }
        return try imageCaptureCell(question: question, indexPath: indexPath, key: key)
    }
    private func textFieldCell(question: Question, indexPath: IndexPath) throws -> NewIssueTextFieldCell {
        let question = fetchedResultsController.object(at: indexPath)
        let cell: NewIssueTextFieldCell = try dq(identifier: .textField, indexPath: indexPath)
        cell.configure(text: question.text, required: question.required)
        guard let key = question.key else {
            cell.textFieldValueDidChange = nil
            return cell
        }
        cell.textFieldValueDidChange = { [weak self] textField in
            self?.updateTextFieldAnswer(key: key, text: textField?.text)
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let question = fetchedResultsController.object(at: indexPath)
        do {
            switch try question.format() {
            case .location:
                return try locationCell(question: question, indexPath: indexPath)
            case .image:
                return try imageCell(question: question, indexPath: indexPath)
            case .label:
                let cell: NewIssueBodyLabelCell = try dq(identifier: .label, indexPath: indexPath)
                cell.label?.text = question.text
                return cell
            case .picker:
                let question = fetchedResultsController.object(at: indexPath)
                let cell: NewIssuePickerCell = try dq(identifier: .picker, indexPath: indexPath)
                cell.label?.text = question.text
                cell.values = question.sortedValues()
                return cell
            case .input:
                return try textFieldCell(question: question, indexPath: indexPath)
            case .textarea:
                let question = fetchedResultsController.object(at: indexPath)
                let cell: NewIssueTextViewCell = try dq(identifier: .textView, indexPath: indexPath)
                cell.label?.text = question.text
                return cell
            case .datepicker:
                let question = fetchedResultsController.object(at: indexPath)
                let cell: NewIssueDatePickerCell = try dq(identifier: .datePicker, indexPath: indexPath)
                cell.label?.text = question.text
                return cell
            }
        } catch {
            preconditionFailure()
        }
    }
}

extension NewIssueDetailViewController : NewIssueDisplayImageViewCellDelegate {
    func removeMedia() {
        
    }
}
