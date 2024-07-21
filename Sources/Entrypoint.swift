import Vapor

@main
struct VaporConnect {
    static func main() async throws {
        let app = try await Application.make()
        app.http.server.configuration.port = 8282
        addCorsMiddleware(app)

        listenToIncomingEvents(app)

        try await app.execute()
    }

    static func addCorsMiddleware(_ app: Application) {
        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET],
            allowedHeaders: []
        )
        let cors = CORSMiddleware(configuration: corsConfiguration)
        app.middleware.use(cors, at: .beginning)
    }

    static func listenToIncomingEvents(_ app: Application) {
        print("Listening to events...")

        app.get("callback", ":event") { [unowned app] req in
            guard let event = req.parameters.get("event"), !event.isEmpty else {
                throw Abort(.badRequest, reason: "No event")
            }

            let finished = event == "Build Succeeded"

            defer {
                if finished {
                    print("Finished, shutting down")
                    Task { try await app.asyncShutdown() }
                }
            }

            return "Got event: " + event
        }
    }
}
