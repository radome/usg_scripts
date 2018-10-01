# string_example = "curl -X POST -H 'Content-Type: application/vnd.api+json' -i 'http://production.psd.sanger.ac.uk:7462/v1/print_jobs' --data '{\"data\":{\"attributes\":{\"printer_name\":\"f225bc\",\"label_template_id\":1,\"labels\":{\"body\":[{\"location\":{\"location\":\"SCGC-10X-00000002\",\"barcode\":\"SCGC-10X-00000002\"}},{\"location\":{\"location\":\"SCGC-10X-00000002\",\"barcode\":\"SCGC-10X-00000002\"}},{\"location\":{\"location\":\"SCGC-10X-00000002\",\"barcode\":\"SCGC-10X-00000002\"}},{\"location\":{\"location\":\"SCGC-10X-00000003\",\"barcode\":\"SCGC-10X-00000003\"}},{\"location\":{\"location\":\"SCGC-10X-00000003\",\"barcode\":\"SCGC-10X-00000003\"}},{\"location\":{\"location\":\"SCGC-10X-00000003\",\"barcode\":\"SCGC-10X-00000003\"}}]}}}}'"

def add_barcode_str(barcode_text,build_string)
  build_string = build_string+"{\"location\":{\"location\":\"#{barcode_text}\",\"barcode\":\"#{barcode_text}\"}},{\"location\":{\"location\":\"#{barcode_text}\",\"barcode\":\"#{barcode_text}\"}},{\"location\":{\"location\":\"#{barcode_text}\",\"barcode\":\"#{barcode_text}\"}},"
  return build_string
end

def print_repeating_barcodes(main_root,first_num,last_num,printer_name='f225bc',mode)
  build_string = "curl -X POST -H 'Content-Type: application/vnd.api+json' -i 'http://production.psd.sanger.ac.uk:7462/v1/print_jobs' --data '{\"data\":{\"attributes\":{\"printer_name\":\"#{printer_name}\",\"label_template_id\":1,\"labels\":{\"body\":["
  terminal_str = "]}}}}'"
  for num in (first_num..last_num)
    barcode_text = main_root+num.to_s.rjust(8, '0')
    puts "#{barcode_text}"
    if num == last_num
      build_string = add_barcode_str(barcode_text,build_string)
      build_string = build_string.chomp(',')+terminal_str
    else
      build_string = add_barcode_str(barcode_text,build_string)
    end
  end
  puts build_string
  puts `#{build_string.to_s}` unless mode != 'run'
end

# print_repeating_barcodes("SCGC-10X-",x,y,printer_name='f225bc',mode)