//
//  FileListTableViewController.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 12/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit
import QuickLook

protocol ClosingDelegate: AnyObject {
    func didTouchCloseButton()
}

class FileListTableViewController: UITableViewController {

    private let collation = UILocalizedIndexedCollation.current()
    private let cellIdentifier = "FileCell"

    var didSelectFile: ((FBFile) -> Void)?
    var allowEditing: Bool = false
    weak var closingDelegate: ClosingDelegate!

    private var files = [FBFile]()
    private var initialPath: URL?
    private let parser = FileParser.sharedInstance
    private let previewManager = PreviewManager()
    private var sections: [[FBFile]] = []
    private var nonEmptySections: [[FBFile]] {
        return sections.filter { !$0.isEmpty }
    }
    private var showCloseButton: Bool = true

    private var filteredFiles = [FBFile]()
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Initializer
    init(initialPath: URL, showCloseButton: Bool = true) {
        super.init(style: .insetGrouped)
        self.initialPath = initialPath
        self.showCloseButton = showCloseButton
        self.title = initialPath.lastPathComponent
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupNavigation()
        setupTableView()
        prepareData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if searchController.isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    // MARK: - Setup Methods
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func setupNavigation() {
        if showCloseButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Close",
                style: .plain,
                target: self,
                action: #selector(dismissView)
            )
        }
    }

    @objc private func dismissView() {
        closingDelegate.didTouchCloseButton()
    }

    // MARK: - Data Management
    private func prepareData() {
        guard let initialPath else { return }
        files = parser.filesForDirectory(initialPath)
        indexFiles()
    }

    private func indexFiles() {
        let selector: Selector = #selector(getter: FBFile.displayName)
        sections = Array(repeating: [], count: collation.sectionTitles.count)
        if let sortedObjects = collation.sortedArray(from: files, collationStringSelector: selector) as? [FBFile] {
            for object in sortedObjects {
                let sectionNumber = collation.section(for: object, collationStringSelector: selector)
                sections[sectionNumber].append(object)
            }
        }
    }

    private func fileForIndexPath(_ indexPath: IndexPath) -> FBFile {
        if searchController.isActive {
            return filteredFiles[indexPath.row]
        }
        return nonEmptySections[indexPath.section][indexPath.row]
    }

    private func filterContentForSearchText(_ searchText: String) {
        filteredFiles = files.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension FileListTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return searchController.isActive ? 1 : nonEmptySections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFiles.count : nonEmptySections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let selectedFile = fileForIndexPath(indexPath)
        cell.textLabel?.text = selectedFile.displayName
        cell.imageView?.image = selectedFile.type.image()
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchController.isActive, section < nonEmptySections.count else { return nil }
        return collation.sectionTitles[sections.firstIndex(where: { $0 == nonEmptySections[section] }) ?? 0]
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return searchController.isActive ? nil : collation.sectionIndexTitles
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return searchController.isActive ? 0 : collation.section(forSectionIndexTitle: index)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selectedFile = fileForIndexPath(indexPath)
            selectedFile.delete()
            prepareData()
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return allowEditing
    }
}

// MARK: - UITableViewDelegate
extension FileListTableViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFile: FBFile

        if searchController.isActive { selectedFile = filteredFiles[indexPath.row] }
        else                         { selectedFile = fileForIndexPath(indexPath)  }

        if selectedFile.isDirectory {
            let fileListViewController = FileListTableViewController(initialPath: selectedFile.filePath)
            fileListViewController.closingDelegate = closingDelegate
            fileListViewController.didSelectFile = didSelectFile
            navigationController?.pushViewController(fileListViewController, animated: true)
        } else {
            if let didSelectFile = didSelectFile {
                dismiss(animated: true) { didSelectFile(selectedFile) }
            } else {
                let filePreview = previewManager.previewViewControllerForFile(selectedFile)
                filePreview.view.backgroundColor = .systemBackground
                filePreview.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .close,
                    target: self,
                    action: #selector(dismissFilePreview)
                )
                let navController = UINavigationController(rootViewController: filePreview)
                navController.modalPresentationStyle = .fullScreen
                navigationController?.isModalInPresentation = true
                navigationController?.present(navController, animated: true)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func dismissFilePreview() {
        dismiss(animated: true)
    }

}

// MARK: - UISearchControllerDelegate, UISearchResultsUpdating
extension FileListTableViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
}


//MARK: Preview (UIViewControllerPreviewingDelegate)

