# values = ["HYYHKCCXY","lc2","12","20324724","22102300","6",nil,nil]
# descriptors = ["Chip Barcode", "Operator", "CBOT", "-20 Temp. Read 1 Cluster Kit Lot #", "-20 Temp. Cluster Kit RGT #", "Pipette Carousel", "PhiX lot #", "Comment"]
def add_events_to_batch(batch_id, user_login, descriptors, values)
  event_hash = Hash[descriptors.zip(values)]
  batch = Batch.find batch_id
  user = User.find_by(login: user_login)
  batch.requests.each do |request|
    le = LabEvent.create!(description: "Cluster generation", batch_id: batch.id, user_id: user.id, eventful_id: request.id, eventful_type: "Request", descriptor_fields: descriptors)
    le.descriptors = event_hash.each_with_object({}) do |(key, value), hash|
      hash[key] = value
    end
    le.save!
  end
end

# with pre-built event_hash
def add_events_to_batch(batch_id, user_login, description, event_hash)
  batch = Batch.find batch_id
  user = User.find_by(login: user_login)
  batch.requests.each do |request|
    le = LabEvent.create!(description: description, batch_id: batch.id, user_id: user.id, eventful_id: request.id, eventful_type: "Request", descriptor_fields: event_hash.keys)
    le.descriptors = event_hash.each_with_object({}) do |(key, value), hash|
      hash[key] = value
    end
    le.save!
  end
end