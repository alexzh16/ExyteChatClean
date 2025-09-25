//
//  Created by Alex.M on 04.07.2022.
//

import Foundation

extension Date {
   func startOfDay() -> Date {
      Calendar.current.startOfDay(for: self)
   }
   
   func isSameDay(_ date: Date) -> Bool {
      Calendar.current.isDate(self, inSameDayAs: date)
   }
   
   func randomTime() -> Date {
      var hour = Int.random(in: 0...23)
      var minute = Int.random(in: 0...59)
      var second = Int.random(in: 0...59)
      
      let current = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
      let curHour = current.hour ?? 23
      let curMinute = current.minute ?? 59
      let curSecond = current.second ?? 59
      
      if hour > curHour {
         hour = curHour
      } else if hour == curHour, minute > curMinute {
         minute = curMinute
      } else if hour == curHour, minute == curMinute, second > curSecond {
         second = curSecond
      }
      
      var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
      components.hour = hour
      components.minute = minute
      components.second = second
      return Calendar.current.date(from: components)!
   }
   
   // 1 hour ago, 2 days ago...
   func formatAgo() -> String {
      let result = DateFormatter.agoFormatter.localizedString(for: self, relativeTo: Date())
      if result.contains("second") {
         return "Just now"
      }
      return result
   }
}
