import SwiftUI

struct WidgetContent: Codable, Equatable {
    var status: String
    var transcript: String
    var assistantText: String
    var selectedOption: String?
    var updatedAt: Date

    static let sample = WidgetContent(
        status: "Hermes listo",
        transcript: "Pulsa PTT en Launchpad y habla.",
        assistantText: "Las respuestas del agente apareceran aqui.",
        selectedOption: nil,
        updatedAt: .now
    )

    static let placeholder = WidgetContent(
        status: "Sin conexion",
        transcript: "Esperando eventos del bus.",
        assistantText: "Abre la app companion para sincronizar Hermes.",
        selectedOption: nil,
        updatedAt: .now
    )
}
