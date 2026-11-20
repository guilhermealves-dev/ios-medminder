import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case ptBR = "pt-BR"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .ptBR: return "Português (Brasil) 🇧🇷"
        case .en: return "English 🇺🇸"
        }
    }
}

public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    private let userDefaultsKey = "selected_app_language"
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default to pt-BR if system language is Portuguese, otherwise default to pt-BR as requested
            let preferred = Locale.preferredLanguages.first ?? "pt-BR"
            if preferred.hasPrefix("pt") {
                self.currentLanguage = .ptBR
            } else {
                self.currentLanguage = .ptBR // Default to pt-BR as primary user language
            }
        }
    }
    
    public func string(for key: String) -> String {
        let isPt = currentLanguage == .ptBR
        
        switch key {
        // MARK: Tabs
        case "tab_today": return isPt ? "Hoje" : "Today"
        case "tab_meds": return isPt ? "Remédios" : "Meds"
        case "tab_cabinet": return isPt ? "Armário" : "Cabinet"
        case "tab_progress": return isPt ? "Progresso" : "Progress"
        case "tab_settings": return isPt ? "Ajustes" : "Settings"
            
        // MARK: Today
        case "today_title": return isPt ? "Hoje" : "Today"
        case "daily_adherence": return isPt ? "Adesão Diária" : "Daily Adherence"
        case "no_meds_scheduled": return isPt ? "Nenhum remédio agendado" : "No meds scheduled"
        case "doses_taken_format": return isPt ? "%d de %d doses tomadas" : "%d of %d doses taken"
        case "take_all": return isPt ? "Tomar Todos" : "Take All"
        case "take_now": return isPt ? "Tomar Agora" : "Take Now"
        case "low_stock_banner": return isPt ? "Estoque Baixo: %@" : "Low Stock: %@"
        case "only_doses_left": return isPt ? "Restam apenas %d doses. Reponha logo!" : "Only %d doses left. Refill soon!"
        case "free_day_msg": return isPt ? "Aproveite seu dia ou adicione remédios para acompanhar seu tratamento." : "Enjoy your free day or add medications to track your treatment."
        case "add_medication": return isPt ? "Adicionar Medicamento" : "Add Medication"
            
        // MARK: Status
        case "status_taken": return isPt ? "Tomado" : "Taken"
        case "status_skipped": return isPt ? "Pulado" : "Skipped"
        case "status_snoozed": return isPt ? "Adiado" : "Snoozed"
        case "status_pending": return isPt ? "Pendente" : "Pending"
        case "action_snooze": return isPt ? "Adiar (15m)" : "Snooze (15m)"
        case "action_skip": return isPt ? "Pular" : "Skip"
        case "action_take": return isPt ? "Tomar" : "Take"
            
        // MARK: Periods
        case "period_morning": return isPt ? "Manhã" : "Morning"
        case "period_afternoon": return isPt ? "Tarde" : "Afternoon"
        case "period_evening": return isPt ? "Noite" : "Evening"
        case "period_night": return isPt ? "Madrugada" : "Night"
            
        // MARK: Forms
        case "form_capsule": return isPt ? "Cápsula" : "Capsule"
        case "form_tablet": return isPt ? "Comprimido" : "Tablet"
        case "form_liquid": return isPt ? "Líquido / Xarope" : "Liquid / Syrup"
        case "form_drops": return isPt ? "Gotas" : "Drops"
        case "form_injection": return isPt ? "Injeção" : "Injection"
        case "form_inhaler": return isPt ? "Inalador" : "Inhaler"
        case "form_patch": return isPt ? "Adesivo" : "Patch"
        case "form_spray": return isPt ? "Spray" : "Spray"
            
        // MARK: Meals
        case "meal_anytime": return isPt ? "A qualquer momento" : "Anytime"
        case "meal_before": return isPt ? "Antes da refeição" : "Before meal"
        case "meal_with": return isPt ? "Com a refeição" : "With meal"
        case "meal_after": return isPt ? "Após a refeição" : "After meal"
            
        // MARK: Frequencies
        case "freq_everyday": return isPt ? "Todos os dias" : "Every day"
        case "freq_specific_days": return isPt ? "Dias específicos da semana" : "Specific days of week"
        case "freq_every_x_hours": return isPt ? "A cada X horas" : "Every X hours"
        case "freq_as_needed": return isPt ? "Conforme necessário (SOS)" : "As needed (PRN)"
            
        // MARK: Colors
        case "color_sapphire": return isPt ? "Azul Safira" : "Sapphire Blue"
        case "color_coral": return isPt ? "Vermelho Coral" : "Coral Red"
        case "color_emerald": return isPt ? "Verde Esmeralda" : "Emerald Green"
        case "color_amber": return isPt ? "Laranja Âmbar" : "Amber Orange"
        case "color_violet": return isPt ? "Roxo Ametista" : "Amethyst Purple"
        case "color_teal": return isPt ? "Ciano / Teal" : "Teal Cyan"
        case "color_pink": return isPt ? "Rosa Chiclete" : "Bubblegum Pink"
            
        // MARK: Add/Edit View
        case "edit_medication": return isPt ? "Editar Medicamento" : "Edit Medication"
        case "new_medication": return isPt ? "Novo Medicamento" : "Add Medication"
        case "basic_info": return isPt ? "Informações Básicas" : "Basic Info"
        case "med_name_label": return isPt ? "Nome do Remédio" : "Medication Name"
        case "med_name_placeholder": return isPt ? "Nome do remédio (ex: Paracetamol)" : "Medication Name (e.g. Ibuprofen)"
        case "strength_placeholder": return isPt ? "Dosagem (ex: 500 mg, 10 ml)" : "Strength / Dosage (e.g. 400 mg)"
        case "appearance": return isPt ? "Aparência do Remédio" : "Pill Appearance"
        case "schedule": return isPt ? "Frequência e Rotina" : "Schedule"
        case "frequency_label": return isPt ? "Frequência" : "Frequency"
        case "meal_label": return isPt ? "Tomar com alimento?" : "Take with food?"
        case "dose_times_header": return isPt ? "Horários das Doses" : "Dose Times"
        case "dose_number": return isPt ? "Dose %d" : "Dose %d"
        case "add_another_time": return isPt ? "Adicionar Horário de Dose" : "Add Another Dose Time"
        case "inventory_header": return isPt ? "Estoque & Armário" : "Inventory & Refill"
        case "current_stock": return isPt ? "Estoque Atual" : "Current Stock"
        case "pills_unit": return isPt ? "unidades" : "pills"
        case "refill_reminder": return isPt ? "Alerta de Reposição" : "Refill Reminder"
        case "alert_when_below": return isPt ? "Avisar quando restar menos de" : "Alert When Below"
        case "notes_header": return isPt ? "Observações" : "Notes"
        case "notes_placeholder": return isPt ? "Instruções do médico, armazenamento, etc." : "Doctor instructions, storage conditions, etc."
        case "save": return isPt ? "Salvar" : "Save"
        case "cancel": return isPt ? "Cancelar" : "Cancel"
        case "select_time": return isPt ? "Selecionar Horário" : "Select Time"
        case "add": return isPt ? "Adicionar" : "Add"
            
        // MARK: Meds List
        case "medications_title": return isPt ? "Medicamentos" : "Medications"
        case "active_medications": return isPt ? "Medicamentos Ativos (%d)" : "Active Medications (%d)"
        case "paused_medications": return isPt ? "Pausados / Finalizados (%d)" : "Paused / Finished (%d)"
        case "search_medications": return isPt ? "Buscar remédio..." : "Search medications..."
        case "no_meds_added": return isPt ? "Nenhum remédio cadastrado" : "No medications added"
        case "no_meds_hint": return isPt ? "Toque no botão + para cadastrar seu primeiro remédio." : "Tap the + button to add your first medicine."
        case "no_search_results": return isPt ? "Nenhum resultado encontrado" : "No matching medications"
        case "no_search_hint": return isPt ? "Tente buscar por outro nome ou dosagem." : "Try searching for a different name."
        case "pills_left_badge": return isPt ? "%d restantes" : "%d left"
        case "pause": return isPt ? "Pausar" : "Pause"
        case "resume": return isPt ? "Retomar" : "Resume"
        case "delete": return isPt ? "Excluir" : "Delete"
            
        // MARK: Cabinet
        case "cabinet_title": return isPt ? "Armário" : "Cabinet"
        case "refill_needed": return isPt ? "Reposição Necessária" : "Refill Needed"
        case "pills_remaining_below": return isPt ? "%d restantes (abaixo de %d)" : "%d pills remaining (below %d)"
        case "refill_button": return isPt ? "Repor" : "Refill"
        case "cabinet_inventory": return isPt ? "Estoque do Armário (%d)" : "Pill Cabinet Inventory (%d)"
        case "in_stock_label": return isPt ? "%d em estoque" : "%d pills in stock"
        case "days_left_estimate": return isPt ? "~%d dias restantes" : "~%d days left"
        case "depleted": return isPt ? "Esgotado" : "Depleted"
        case "refill_medication_title": return isPt ? "Repor Estoque" : "Refill Medication"
        case "units_to_add": return isPt ? "Quantidade a adicionar" : "Units to add"
        case "confirm": return isPt ? "Confirmar" : "Confirm"
        case "standard_dose": return isPt ? "Dose padrão" : "Standard dose"
            
        // MARK: Progress / History
        case "progress_title": return isPt ? "Progresso" : "Progress"
        case "adherence_overview": return isPt ? "Visão Geral de Adesão" : "Health Adherence Overview"
        case "adherence_7_days": return isPt ? "Adesão 7 Dias" : "7-Day Adherence"
        case "adherence_30_days": return isPt ? "Adesão 30 Dias" : "30-Day Adherence"
        case "consistency_title": return isPt ? "Excelente consistência!" : "Great consistency!"
        case "consistency_msg": return isPt ? "Tome seus remédios no horário certo para manter seu tratamento em dia." : "Keep taking your meds on time to stay healthy."
        case "dose_activity_log": return isPt ? "Histórico de Doses" : "Dose Activity Log"
        case "no_logs_msg": return isPt ? "Nenhuma dose registrada ainda. Ao marcar remédios na aba Hoje, o histórico será exibido aqui." : "No recorded doses yet. Take doses in the Today tab to build your log history."
            
        // MARK: Settings
        case "settings_title": return isPt ? "Ajustes" : "Settings"
        case "language_section": return isPt ? "Idioma / Language" : "Language"
        case "app_language": return isPt ? "Idioma do Aplicativo" : "App Language"
        case "reminders_section": return isPt ? "Lembretes e Notificações" : "Reminders"
        case "notification_reminders": return isPt ? "Notificações de Lembrete" : "Notification Reminders"
        case "status_enabled": return isPt ? "Ativado" : "Enabled"
        case "action_enable": return isPt ? "Ativar" : "Enable"
        case "send_test_reminder": return isPt ? "Enviar Teste de Lembrete (5 seg)" : "Send Test Reminder (5 sec)"
        case "reminders_footer": return isPt ? "O MedMinder usa notificações locais do iOS para avisar quando for a hora de cada remédio." : "MedMinder uses local iOS notifications to alert you when it's time for each dose."
        case "preferences_section": return isPt ? "Preferências" : "Preferences"
        case "snooze_duration": return isPt ? "Tempo de Adiamento" : "Snooze Duration"
        case "snooze_time_val": return isPt ? "15 minutos" : "15 minutes"
        case "refill_buffer": return isPt ? "Margem de Alerta de Refil" : "Refill Alert Buffer"
        case "refill_buffer_val": return isPt ? "5 doses restantes" : "5 doses remaining"
        case "data_section": return isPt ? "Gerenciamento de Dados" : "Data"
        case "clear_all_data": return isPt ? "Limpar Todos os Dados" : "Clear All Data"
        case "clear_all_confirm_title": return isPt ? "Apagar todos os dados?" : "Clear All Data?"
        case "clear_all_confirm_msg": return isPt ? "Isso apagará todos os seus medicamentos cadastrados e histórico de doses." : "This will permanently remove all medications and recorded logs."
        case "clear_button": return isPt ? "Apagar Tudo" : "Clear All"
        case "about_section": return isPt ? "Sobre o MedMinder" : "About"
        case "app_name_label": return isPt ? "Nome do App" : "App Name"
        case "version_label": return isPt ? "Versão" : "Version"
        case "platform_label": return isPt ? "Plataforma" : "Platform"
        case "test_notification_scheduled": return isPt ? "Lembrete de Teste Agendado" : "Test Notification Scheduled"
        case "test_notification_msg": return isPt ? "Bloqueie seu aparelho ou saia do app para ver a notificação em 5 segundos." : "Lock your device or switch apps to see the reminder in 5 seconds."
        case "ok": return isPt ? "OK" : "OK"
            
        default:
            return key
        }
    }
}

// Global convenience accessor
public func loc(_ key: String) -> String {
    LanguageManager.shared.string(for: key)
}
