import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

// MARK: - QR Login

struct QRLoginView: View {
    @State private var qrCode = ""
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: KometSpacing.xl) {
            if isLoading {
                ProgressView()
            } else if !qrCode.isEmpty, let img = generateQR(qrCode) {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(KometSpacing.lg)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: KometSpacing.sm, style: .continuous))

                Text(String(localized: "Scan this code with another device to log in"))
                    .font(.kometCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, KometSpacing.xl)
            }

            Button(String(localized: "Refresh")) { Task { await load() } }
                .buttonStyle(.borderedProminent)
                .tint(.kometAccent)
        }
        .navigationTitle(String(localized: "QR Login"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        qrCode = (try? await APIService.shared.requestQRCode()) ?? ""
        isLoading = false
    }

    private func generateQR(_ string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: scaled)
    }
}

// MARK: - QR Scanner

struct QRScannerView: View {
    let onScan: (String) -> Void
    @State private var isAuthorized = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if isAuthorized {
                QRCaptureView(onScan: { value in
                    onScan(value)
                    dismiss()
                })
                .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    String(localized: "Camera access required"),
                    systemImage: "camera",
                    description: Text(String(localized: "Please allow camera access in Settings"))
                )
            }

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 200, height: 200)
                Spacer()
            }
        }
        .navigationTitle(String(localized: "Scan QR Code"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let status = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = status
        }
    }
}

struct QRCaptureView: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeUIView(context: Context) -> QRCameraView {
        let v = QRCameraView()
        v.onScan = onScan
        return v
    }

    func updateUIView(_ uiView: QRCameraView, context: Context) {}
}

final class QRCameraView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private let session = AVCaptureSession()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        let output = AVCaptureMetadataOutput()
        session.addInput(input)
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            preview.frame = self.bounds
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let qr = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = qr.stringValue else { return }
        session.stopRunning()
        onScan?(value)
    }
}

struct QRAuthorizeView: View {
    @State private var scannedToken = ""

    var body: some View {
        QRScannerView { token in
            scannedToken = token
            Task { try? await APIService.shared.authorizeQR(code: token) }
        }
    }
}
