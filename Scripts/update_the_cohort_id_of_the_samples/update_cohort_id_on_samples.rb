UPDATE_BY = "uuid"
USERNAME = "user"

# Change it to the appropriate URL
url = "bulk_update_sample_action_url"

# samples to update
# It is a hash, the key is the uuid of the sample to update,
# the value is the sample property to update with the new value
#
# REPLACE this hash with the real updates hash!!!
updates = 
{ sample_uuid1 => 
    { "cohort" => new_cohort_name1 },
  sample_uuid2 =>
    { "cohort" => new_cohort_name2 },
  sample_uuid3 =>
    { "cohort" => new_cohort_name3 }
}

parameters = { "bulk_update_sample" => 
  { "user"    => USERNAME,
    "by"      => UPDATE_BY,
    "updates" => updates
  }
}

# convert the hash to a JSON like string
parameter_json = parameters.to_s.gsub("=>", ":").gsub(" ", "")
puts parameter_json

response = 
  `curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d '#{parameter_json}' #{url}`
puts
puts response

puts
puts "Samples has been updated successfully."

