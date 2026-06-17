import WidgetKit
import SwiftUI

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayerName: String
    let prayerTime: String
    let countdown: String
    
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    
    let ayah: String
    let hadith: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(
            date: Date(),
            prayerName: "الفجر",
            prayerTime: "05:15",
            countdown: "01:24",
            fajr: "05:15",
            dhuhr: "12:30",
            asr: "15:45",
            maghrib: "18:50",
            isha: "20:15",
            ayah: "إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ",
            hadith: "خيركم من تعلم القرآن وعلمه"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> ()) {
        let entry = getPrayerEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [PrayerEntry] = []
        let currentDate = Date()
        
        // Generate timeline entries for the next hour, one entry per minute
        for minuteOffset in 0 ..< 60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = getPrayerEntry(for: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getPrayerEntry(for date: Date) -> PrayerEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.rafiqquran.rafiq_quran")
        
        let fajr = userDefaults?.string(forKey: "fajr_time") ?? "05:15"
        let dhuhr = userDefaults?.string(forKey: "dhuhr_time") ?? "12:30"
        let asr = userDefaults?.string(forKey: "asr_time") ?? "15:45"
        let maghrib = userDefaults?.string(forKey: "maghrib_time") ?? "18:50"
        let isha = userDefaults?.string(forKey: "isha_time") ?? "20:15"
        
        let ayah = userDefaults?.string(forKey: "daily_ayah") ?? "إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ"
        let hadith = userDefaults?.string(forKey: "daily_hadith") ?? "خيركم من تعلم القرآن وعلمه"
        
        // Calculate next prayer and countdown
        let nextPrayerInfo = calculateNextPrayer(date: date, fajr: fajr, dhuhr: dhuhr, asr: asr, maghrib: maghrib, isha: isha)
        
        return PrayerEntry(
            date: date,
            prayerName: nextPrayerInfo.name,
            prayerTime: nextPrayerInfo.time,
            countdown: nextPrayerInfo.countdown,
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            ayah: ayah,
            hadith: hadith
        )
    }
    
    private func calculateNextPrayer(date: Date, fajr: String, dhuhr: String, asr: String, maghrib: String, isha: String) -> (name: String, time: String, countdown: String) {
        let calendar = Calendar.current
        let now = date
        
        let prayers = [
            ("الفجر", fajr),
            ("الظهر", dhuhr),
            ("العصر", asr),
            ("المغرب", maghrib),
            ("العشاء", isha)
        ]
        
        var nextPrayerList: [(String, Date)] = []
        
        for prayer in prayers {
            let parts = prayer.1.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = hour
                components.minute = minute
                components.second = 0
                
                if let prayerDate = calendar.date(from: components) {
                    let finalDate = prayerDate < now ? calendar.date(byAdding: .day, value: 1, to: prayerDate)! : prayerDate
                    nextPrayerList.append((prayer.0, finalDate))
                }
            }
        }
        
        if nextPrayerList.isEmpty {
            return ("--", "--:--", "--:--")
        }
        
        nextPrayerList.sort { $0.1 < $1.1 }
        let next = nextPrayerList[0]
        
        let diff = calendar.dateComponents([.hour, .minute], from: now, to: next.1)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        let countdownStr = String(format: "%02d:%02d", hours, minutes)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: next.1)
        
        return (next.0, timeStr, countdownStr)
    }
}

struct RunnerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background color dark green matching app
            Color(red: 15/255, green: 90/255, blue: 71/255)
                .ignoresSafeArea()
            
            // Gold border
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 212/255, green: 175/255, blue: 55/255), lineWidth: 1.5)
                .padding(1)
            
            VStack(spacing: 8) {
                switch family {
                case .systemSmall:
                    smallWidgetView
                case .systemMedium:
                    mediumWidgetView
                default:
                    largeWidgetView
                }
            }
            .padding(12)
            .environment(\.layoutDirection, .rightToLeft) // Force Right-To-Left for Arabic
        }
    }
    
    // 1. Small Widget View (2x1 concept in iOS)
    var smallWidgetView: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("الصلاة القادمة")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.8))
            
            Text(entry.prayerName)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 212/255, green: 175/255, blue: 55/255))
            
            Text(entry.countdown)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("في \(entry.prayerTime)")
                .font(.system(size: 10))
                .foregroundColor(Color.green.opacity(0.3))
        }
    }
    
    // 2. Medium Widget View (2x2 concept in iOS)
    var mediumWidgetView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.countdown)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerName)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 212/255, green: 175/255, blue: 55/255))
                    Text("في \(entry.prayerTime)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            
            Divider()
                .background(Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.2))
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("آية اليوم")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.8))
                Spacer(minLength: 2)
                Text(entry.ayah)
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // 3. Large Widget View (4x2 concept in iOS)
    var largeWidgetView: some View {
        HStack(spacing: 12) {
            // Left part: The 5 prayer times
            VStack(spacing: 4) {
                prayerRow(name: "الفجر", time: entry.fajr)
                Divider().background(Color.white.opacity(0.1))
                prayerRow(name: "الظهر", time: entry.dhuhr)
                Divider().background(Color.white.opacity(0.1))
                prayerRow(name: "العصر", time: entry.asr)
                Divider().background(Color.white.opacity(0.1))
                prayerRow(name: "المغرب", time: entry.maghrib)
                Divider().background(Color.white.opacity(0.1))
                prayerRow(name: "العشاء", time: entry.isha)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.3))
            
            // Right part: Active Info
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Text(entry.countdown)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 212/255, green: 175/255, blue: 55/255))
                    Spacer()
                    Text("الصلاة القادمة: \(entry.prayerName)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                Text(entry.ayah)
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                
                Divider().background(Color.white.opacity(0.1))
                
                Text(entry.hadith)
                    .font(.system(size: 9, design: .serif))
                    .foregroundColor(Color.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func prayerRow(name: String, time: String) -> some View {
        HStack {
            Text(time)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.8))
        }
    }
}

@main
struct RunnerWidget: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RunnerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("رفيق القرآن")
        .description("يعرض مواقيت الصلوات والورد اليومي والعداد التنازلي.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
