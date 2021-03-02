//
//  ALKFileUtils.swift
//  ApplozicSwift
//
//  Created by Sunil on 14/03/19.
//

import ApplozicCore
import AVFoundation
import Contacts
import Foundation

class ALKFileUtils: NSObject {
    func getFileName(filePath: String?, fileMeta: ALFileMetaInfo?) -> String {
        guard let fileMetaInfo = fileMeta, let fileName = fileMetaInfo.name else {
            guard let localPathName = filePath else {
                return ""
            }
            return (localPathName as NSString).lastPathComponent as String
        }
        return fileName
    }

    func getFileSize(filePath: String?, fileMetaInfo: ALFileMetaInfo?) -> String? {
        guard let fileName = filePath else {
            return fileMetaInfo?.getTheSize()
        }

        let filePath = getDocumentDirectory(fileName: fileName).path

        guard let size = ((try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.size]) as Any??), let fileSize = size as? UInt64
        else {
            return ""
        }
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.1f KB", floatSize)
        }

        floatSize /= 1024
        if floatSize < 1023 {
            return String(format: "%.1f MB", floatSize)
        }

        floatSize /= 1024
        return String(format: "%.1f GB", floatSize)
    }

    func getFileExtenion(filePath: String?, fileMeta: ALFileMetaInfo?) -> String {
        guard let localPathName = filePath else {
            guard let fileMetaInfo = fileMeta, let name = fileMetaInfo.name, let pathExtension = URL(string: name)?.pathExtension else {
                return ""
            }
            return pathExtension
        }
        return getDocumentDirectory(fileName: localPathName).pathExtension
    }

    func getDocumentDirectory(fileName: String) -> URL {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docDirPath.appendingPathComponent(fileName)
    }

    func getThumbnail(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            return UIImage(cgImage: cgImage)

        } catch {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    func moveFileToDocuments(fileURL: URL) -> URL? {
        let fileName = fileURL.lastPathComponent
        let uniqueFileName = "\(Int(Date().timeIntervalSince1970 * 1000))-\(fileName)"
        let newFileURL = getDocumentDirectory(fileName: uniqueFileName)
        do {
            if FileManager.default.fileExists(atPath: newFileURL.path) {
                try FileManager.default.removeItem(atPath: newFileURL.path)
            }
            try FileManager.default.moveItem(atPath: fileURL.path, toPath: newFileURL.path)
            return newFileURL
        } catch {
            print("Failed to export video due to error: \(error)")
            return nil
        }
    }

    func saveContact(toDocDirectory cnContact: CNContact) -> String? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let documentsDirectory = paths[0]
        let vcfCARDPath = documentsDirectory + "/CONTACT_\(Date().timeIntervalSince1970 * 1000)_CARD.vcf"

        var contacts = [CNContact]()
        contacts.append(cnContact)

        var vCardData: Data?
        do {
            vCardData = try CNContactVCardSerialization.data(with: contacts)
        } catch {
            return nil
        }

        guard let cardData = vCardData,
              let url = URL(string: vcfCARDPath)
        else {
            return nil
        }

        if let contactImageData = cnContact.imageData {
            var vcString = String(data: cardData, encoding: .utf8)

            let base64Image = contactImageData.base64EncodedString(options: [])
            let vcardImageString = "PHOTO;TYPE=JPEG;ENCODING=BASE64:" + base64Image + "\n"
            vcString = vcString?.replacingOccurrences(of: "END:VCARD", with: vcardImageString + "END:VCARD")
            vCardData = vcString?.data(using: .utf8)
        }
        do {
            try cardData.write(to: url)
        } catch {
            print(error)
            return nil
        }
        return vcfCARDPath
    }

    func saveImageToDocDirectory(image: UIImage) -> String? {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0]
        let timestamp = "IMG-\(Date().timeIntervalSince1970 * 1000).jpeg"
        let filePath = URL(fileURLWithPath: docDirPath).appendingPathComponent(timestamp).path
        let imageData = image.getCompressedImageData()
        if let imageData = imageData {
            NSData(data: imageData).write(toFile: filePath, atomically: true)
        }
        return filePath
    }
}
