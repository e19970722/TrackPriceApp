import AVFoundation
import ComposableArchitecture
import PhotosUI
import SwiftUI
import Vision

// MARK: - ScanLabelView

public struct ScanLabelView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>
    @State private var isFlashOn: Bool = false
    @State private var scanLineOffset: CGFloat = -120
    @State private var selectedPhotoItem: PhotosPickerItem?

    public init(store: StoreOf<AddItemFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                cameraBackgroundView
                scannerOverlayView
                topControlsView
                bottomControlsView
            }
            .ignoresSafeArea()
            .onAppear { startScanLineAnimation() }
            .onChange(of: selectedPhotoItem) { item in
                guard let item else { return }
                processPickedPhoto(item)
            }
        }
    }
}

// MARK: - Subviews

extension ScanLabelView {
    private var cameraBackgroundView: some View {
        CameraPreviewRepresentable(isFlashOn: $isFlashOn, onDateDetected: handleDetectedDate)
            .ignoresSafeArea()
    }

    private var scannerOverlayView: some View {
        VStack {
            Spacer()
            reticleBracketView
                .overlay(scanLineView)
                .clipped()
            statusChipView
                .padding(.top, RipeSpacing.s5)
            Spacer()
        }
    }

    private var reticleBracketView: some View {
        ZStack {
            Color.clear
            cornerBracketsView
        }
        .frame(width: 260, height: 160)
    }

    private var cornerBracketsView: some View {
        ZStack {
            ReticleCorner()
                .frame(width: 260, height: 160)
        }
    }

    private var scanLineView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(.ripeAccent).opacity(0), Color(.ripeAccent), Color(.ripeAccent).opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: scanLineOffset)
    }

    private var statusChipView: some View {
        HStack(spacing: RipeSpacing.s2) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.75)
            Text(L10n.Expiry.scanning)
                .font(CustomFont.label(13))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, RipeSpacing.s4)
        .padding(.vertical, RipeSpacing.s2)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var topControlsView: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                flashToggleButton
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var closeButton: some View {
        Button {
            store.send(.scanAgainTapped)
        } label: {
            controlPillLabel(systemImage: "xmark", title: nil)
        }
        .buttonStyle(.plain)
    }

    private var flashToggleButton: some View {
        Button {
            isFlashOn.toggle()
        } label: {
            controlPillLabel(
                systemImage: isFlashOn ? "bolt.fill" : "bolt.slash",
                title: isFlashOn ? L10n.Expiry.flash : L10n.Expiry.flashOff
            )
        }
        .buttonStyle(.plain)
    }

    private func controlPillLabel(systemImage: String, title: String?) -> some View {
        HStack(spacing: RipeSpacing.s1) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
            if let title {
                Text(title)
                    .font(CustomFont.label(13))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, RipeSpacing.s3)
        .padding(.vertical, RipeSpacing.s2)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var bottomControlsView: some View {
        VStack {
            Spacer()
            HStack(alignment: .center, spacing: 0) {
                galleryPickerButton
                Spacer()
                shutterButton
                Spacer()
                Color.clear.frame(width: 64)
            }
            .padding(.horizontal, RipeSpacing.s6)
            .padding(.bottom, 50)
        }
    }

    private var galleryPickerButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var shutterButton: some View {
        ZStack {
            Circle()
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: 72, height: 72)
            Circle()
                .fill(.white)
                .frame(width: 60, height: 60)
        }
        .onTapGesture {
            // Shutter tap: OCR is continuous; tapping shims as a trigger
        }
    }
}

// MARK: - Helpers

extension ScanLabelView {
    private func startScanLineAnimation() {
        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
            scanLineOffset = 80
        }
    }

    private func handleDetectedDate(_ date: Date, raw: String) {
        store.send(.dateScanned(date, ocrString: raw))
    }

    private func processPickedPhoto(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else { return }
            detectDateInImage(cgImage)
        }
    }

    private func detectDateInImage(_ cgImage: CGImage) {
        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            if let (date, raw) = DatePatternParser.findDate(in: strings) {
                DispatchQueue.main.async {
                    self.store.send(.dateScanned(date, ocrString: raw))
                }
            }
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - ReticleCorner shape

private struct ReticleCorner: View {
    var body: some View {
        Canvas { context, size in
            let length: CGFloat = 24
            let thick: CGFloat = 3
            let r: CGFloat = 6
            let corners: [(CGPoint, CGPoint, CGPoint)] = [
                (CGPoint(x: 0, y: length), CGPoint(x: 0, y: r), CGPoint(x: length, y: 0)),
                (
                    CGPoint(x: size.width - length, y: 0),
                    CGPoint(x: size.width - r, y: 0),
                    CGPoint(x: size.width, y: length)
                ),
                (
                    CGPoint(x: size.width, y: size.height - length),
                    CGPoint(x: size.width, y: size.height - r),
                    CGPoint(x: size.width - length, y: size.height)
                ),
                (
                    CGPoint(x: length, y: size.height),
                    CGPoint(x: r, y: size.height),
                    CGPoint(x: 0, y: size.height - length)
                ),
            ]
            for (start, via, end) in corners {
                var path = Path()
                path.move(to: start)
                path.addArc(tangent1End: via, tangent2End: end, radius: r)
                path.addLine(to: end)
                context.stroke(path, with: .color(.white), lineWidth: thick)
            }
        }
    }
}

// MARK: - CameraPreviewRepresentable

private struct CameraPreviewRepresentable: UIViewRepresentable {
    @Binding var isFlashOn: Bool
    var onDateDetected: (Date, String) -> Void

    func makeUIView(context _: Context) -> CameraPreviewView {
        let view = CameraPreviewView(onDateDetected: onDateDetected)
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context _: Context) {
        uiView.setFlash(isFlashOn)
    }
}

// MARK: - CameraPreviewView

private final class CameraPreviewView: UIView {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let processingQueue = DispatchQueue(label: "scan.label.ocr", qos: .userInitiated)
    private var isProcessingFrame = false
    private var lastDetectionTime: Date = .distantPast
    var onDateDetected: (Date, String) -> Void

    init(onDateDetected: @escaping (Date, String) -> Void) {
        self.onDateDetected = onDateDetected
        super.init(frame: .zero)
        backgroundColor = .black
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startSession() {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async { self?.configureSession() }
        }
    }

    func setFlash(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processingQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }
}

extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard !isProcessingFrame,
              Date().timeIntervalSince(lastDetectionTime) > 1.5,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        isProcessingFrame = true
        let request = VNRecognizeTextRequest { [weak self] req, _ in
            defer { self?.isProcessingFrame = false }
            guard let self,
                  let observations = req.results as? [VNRecognizedTextObservation] else { return }
            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            if let (date, raw) = DatePatternParser.findDate(in: strings) {
                lastDetectionTime = Date()
                DispatchQueue.main.async { self.onDateDetected(date, raw) }
            }
        }
        request.recognitionLevel = .fast
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - DatePatternParser

enum DatePatternParser {
    private static let keywords = ["BEST BEFORE", "BB", "USE BY", "EXP", "EXPIRY", "EXPIRES", "BEST BY"]

    static func findDate(in strings: [String]) -> (Date, String)? {
        let fullText = strings.joined(separator: "\n").uppercased()

        // Look for keyword + date on same or next line
        for keyword in keywords {
            guard let range = fullText.range(of: keyword) else { continue }
            let after = String(fullText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let date = parseDate(from: after) {
                return (date, "\(keyword) \(after.prefix(20))")
            }
        }

        // Fallback: any string that looks like a date
        for string in strings {
            if let date = parseDate(from: string.uppercased()) {
                return (date, string)
            }
        }
        return nil
    }

    private static func parseDate(from string: String) -> Date? {
        let formatters: [(String, String)] = [
            ("dd MMM yyyy", "\\d{1,2}\\s[A-Z]{3}\\s\\d{4}"),
            ("MM/dd/yyyy",  "\\d{1,2}/\\d{1,2}/\\d{4}"),
            ("yyyy-MM-dd",  "\\d{4}-\\d{2}-\\d{2}"),
            ("dd/MM/yyyy",  "\\d{1,2}/\\d{1,2}/\\d{4}"),
            ("MMM dd yyyy", "[A-Z]{3}\\s\\d{1,2}\\s\\d{4}"),
            ("MM/dd/yy",    "\\d{1,2}/\\d{1,2}/\\d{2}"),
        ]

        for (format, pattern) in formatters {
            if let match = string.range(of: pattern, options: .regularExpression) {
                let candidate = String(string[match])
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = format
                if let date = df.date(from: candidate) {
                    return date
                }
            }
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    ScanLabelView(store: Store(initialState: AddItemFeature.State()) { AddItemFeature() })
}
