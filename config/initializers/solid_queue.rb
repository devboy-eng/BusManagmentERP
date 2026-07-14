SolidQueue.connects_to = { database: { writing: :queue } } unless Rails.env.production?
