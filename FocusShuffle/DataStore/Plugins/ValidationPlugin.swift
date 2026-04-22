import Supabase
import Foundation

final class ValidationPlugin: Validator {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://itlivvdgzlvrcdcustof.supabase.co")!,
            supabaseKey: "sb_publishable_giK41FRvKgJuPN22otCfvQ_3pldx0dj"
        )
    }
    
    func verify() async throws -> Bool {
        do {
            let rows: [VerificationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let row = rows.first else {
                return false
            }
            
            return row.isValid
        } catch {
            print("🎯 [FocusShuffle] Verification failed: \(error)")
            throw error
        }
    }
}

struct VerificationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}
