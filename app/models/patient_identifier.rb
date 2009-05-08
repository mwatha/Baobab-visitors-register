class PatientIdentifier < ActiveRecord::Base
  include Openmrs

  set_table_name "patient_identifier"
  set_primary_keys :patient_id, :identifier, :identifier_type

  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, :class_name => "Patient", :foreign_key => :patient_id

  def self.calculate_checkdigit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      digit = digit * 2 if index%2==parity
      digit = digit - 9 if digit > 9
      sum = sum + digit
    end
    
    checkdigit = 0
    checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0
    return checkdigit
  end

  def self.create(patient_id, identifier, identifier_type_name)
    type_id = PatientIdentifierType.find_by_name(identifier_type_name).id rescue nil
    return false if type_id.blank? || patient_id.blank? || identifier.blank?
    patient_identifier = self.new()
    patient_identifier.patient_id = patient_id
    patient_identifier.identifier = identifier.to_s
    patient_identifier.identifier_type = type_id
    patient_identifier.save
  end
end
