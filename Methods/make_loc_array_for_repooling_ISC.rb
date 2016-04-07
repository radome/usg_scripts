def make_loc_array(rows,col,locs)
  rows.each do |row|
    locs << row+col
  end
  return locs
end

rows = ['a','b','c','d','e','f','g','h']
cols = ['1','2','3','4','5','6','7','8','9','10','11']
xp_barcodes = ['123456']
xp_barcodes.each do |xp_barcode|
  cols.each do |col|
    locs =[]
    make_loc_array(rows,col,locs)
    puts "#{locs}"
    repool(xp_barcode,locs,mode)
  end; nil
end
