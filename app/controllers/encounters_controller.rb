class EncountersController < ApplicationController

  def create
    encounter = Encounter.create(params[:encounter])
    if encounter.type.name =~ /OUTPATIENT DIAGNOSIS|REFERRED/
      if params[:select].to_s =="option2"
        encounter_type_id= EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").id
      elsif params[:select].to_s =="option1"
        encounter_type_id = EncounterType.find_by_name("REFERRED").id 
      end

      encounter.type = EncounterType.find(encounter_type_id) rescue nil
      encounter.save unless encounter_type_id.blank?
    end

    (params[:observations] || []).each{|observation|

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = "coded_or_text group_id boolean coded drug datetime numeric modifier text".split(" ").map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0
      observation[:encounter_id] = encounter.id
      observation[:obs_datetime] ||= Time.now()
      observation[:person_id] ||= encounter.patient_id
      observation[:concept_name] ||= "OUTPATIENT DIAGNOSIS" if encounter.type.name == "OUTPATIENT DIAGNOSIS"
      Observation.create(observation)
    }
    redirect_to "/patients/show/#{params[:encounter][:patient_id]}"
  end

  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) 
    redirect_to "/" and return unless @patient
    redirect_to next_task(@patient) and return unless params[:encounter_type]
    redirect_to :action => :create, 'encounter[encounter_type_name]' => params[:encounter_type].upcase, 'encounter[patient_id]' => @patient.id and return if ['registration'].include?(params[:encounter_type])
    
    concept_set = ConceptName.find_by_name('MALAWI NATIONAL DIAGNOSIS').concept
    @diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, 
                                      :conditions => ['concept_set = ?', concept_set.id],
                                      :include => [:name]).map(&:name)
    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def diagnoses
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    concept_set = ConceptName.find_by_name('MALAWI NATIONAL DIAGNOSIS').concept
    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, 
                                      :conditions => ['concept_set = ?', concept_set.id],
                                      :include => [:name])
    valid_answers = diagnosis_concepts.map{|concept| 
      name = concept.name.name rescue nil
      name.match(search_string) ? name : nil rescue nil
    }.compact
    outpatient_diagnosis = ConceptName.find_by_name("OUTPATIENT DIAGNOSIS").concept
    #XXX common diagnoses disabled due to polluted previous answers at CMED sites
    previous_answers = [] #Observation.find_most_common(outpatient_diagnosis, search_string)
    suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
    render :text => "<li>" + suggested_answers.join("</li><li>") + "</li>"
  end

  def treatment
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    valid_answers = []
    unless search_string.blank?
      drugs = Drug.find(:all, :conditions => ["retired = 0 AND name LIKE ?", '%' + search_string + '%'])
      valid_answers = drugs.map {|drug| drug.name.upcase }
    end
    treatment = ConceptName.find_by_name("TREATMENT").concept
    previous_answers = Observation.find_most_common(treatment, search_string)
    suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
    render :text => "<li>" + suggested_answers.join("</li><li>") + "</li>"
  end
  
  def locations
    search_string = (params[:search_string] || 'neno').upcase
    filter_list = params[:filter_list].split(/, */) rescue []    
    locations =  Location.find(:all, :select =>'name', :conditions => ["retired = 0 AND name LIKE ?", '%' + search_string + '%'])
    render :text => "<li>" + locations.map{|location| location.name }.join("</li><li>") + "</li>"
  end

end
