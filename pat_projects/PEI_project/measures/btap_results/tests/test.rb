require '/usr/local/openstudio-2.6.0/Ruby/openstudio'
require 'openstudio-standards'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'optparse'
begin
  require 'openstudio_measure_tester/test_helper'
rescue LoadError
  puts 'OpenStudio Measure Tester Gem not installed -- will not be able to aggregate and dashboard the results of tests'
end
require_relative '../measure.rb'
require 'fileutils'
require 'minitest/unit'
require 'optparse'


class BTAPResults_Test < Minitest::Test


  def test_qaqc()

    # check if there are any command line arguments, if there are run those
    input_args = ARGV

    #building_type = 'Outpatient'
    #building_type = 'LargeHotel'
    building_type = 'FullServiceRestaurant'
    #building_type = 'Warehouse'
    #building_type = 'LargeOffice'
    #building_type = 'MediumOffice'
    #building_type = 'MidriseApartment'

    #epw_file = "CAN_AB_Banff.CS.711220_CWEC2016.epw"
    #epw_file = "CAN_AB_Calgary.Intl.AP.718770_CWEC2016.epw"
    #epw_file = "CAN_AB_Edmonton.Intl.AP.711230_CWEC2016.epw"
    #epw_file = "CAN_QC_Kuujjuaq.AP.719060_CWEC2016.epw"
    epw_file = "CAN_YT_Whitehorse.Intl.AP.719640_CWEC2016.epw"
    #epw_file = "CAN_BC_Prince.George.Intl.AP.718960_CWEC2016.epw"
    #epw_file = "CAN_MB_Winnipeg-Richardson.Intl.AP.718520_CWEC2016.epw"

    #template = 'NECB2011'
    #template = 'NECB2015'
    template = 'NECB2017'

    # If you want openstudio-standards to make an osm for you set use_existing_osm to 'true'
    use_existing_osm = false
    # If you to use an osm other than those used for regression tests set 'custom_file' to the file name
    #custom_file = 'LargeHotel-NECB2017-CAN_AB_Edmonton.Intl.AP.711230_CWEC2016_expected_result.osm'
    #custom_file = 'FullServiceRestaurant-NECB2015-CAN_AB_Calgary.Intl.AP.718770_CWEC2016_expected_result_test.osm'
    #custom_file = 'LargeHotel-NECB2017-CAN_AB_Calgary.Intl.AP.718770_CWEC2016_expected_result_HP_mod.osm'
    #custom_file = 'LargeHotel-NECB2017-CAN_QC_Kuujjuaq.AP.719060_CWEC2016_expected_result_HP_mod.osm'
    custom_file = nil
    # Change this folder to where the custom file is (starting from btap_costing/)
    @test_fold = "/os_standards_reg_tests/"

    # If you already ran the simulation and have the results set the location of the results folder here
    # (starting from btap_costing/).  Do not add starting and ending '/'.  Set to nil if you have not already run a
    # simulation.
    #@test_output = "testdir_QC"
    @test_output = nil

    if use_existing_osm == true && custom_file.nil? && input_args.empty?
      if epw_file == "CAN_AB_Calgary.Intl.AP.718770_CWEC2016.epw" || epw_file == "CAN_QC_Kuujjuaq.AP.719060_CWEC2016.epw"
        @test_file = building_type + '-' + template + '-' + epw_file[0..-5] + '_expected_result.osm'
        puts ' '
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts "Testing with existing test file: #{@test_file}"
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts ' '
      else
        puts ' '
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts 'You have selected to use an OpenStudio-standards NECB regression test file but have selected an incorrect weather file.  Will now generate osm via OpenStudio-standards.'
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts ' '
      end
    elsif use_existing_osm == true && input_args.empty? && @test_output.nil? && !custom_file.nil?
      @test_file = custom_file
      puts ' '
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      puts "Testing with existing custom test file: #{@test_file}"
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      puts ' '
    elsif use_existing_osm == true && input_args.empty? && !@test_output.nil? && !custom_file.nil?
      @test_file = custom_file
      puts ' '
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      puts "Testing with existing results in folder: #{@test_output}"
      puts "Testing with existing file: #{@test_file}"
      puts "In folder: #{@test_fold}"
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      puts ' '
    end
    # Set 'autozone' to false if you do not want openstudio to run with the auto thermal zoning feature enabled.
    autozone = true

    unless input_args.empty?
      if ((input_args.length / 3).to_i) * 3 < input_args.length
        puts " "
        puts "Incorrect number of arguments, running default buildings:"
        puts building_type
        puts " "
        puts "With default weather files:"
        puts epw_file
        puts " "
        puts "With default templates"
        puts template
        puts " "
      else
        (0..(input_args.length - 1)).step(3) do |index|
          building_type = input_args[index]
          epw_file = input_args[index + 1]
          template = input_args[index + 2]
        end
      end
    end

    create_model_simulate_and_qaqc_regression_test(epw_file: epw_file,
                                                   template: template,
                                                   building_type: building_type,
                                                   auto_zone: autozone
    )


  end


  def create_model_simulate_and_qaqc_regression_test(epw_file:,
                                                     template:,
                                                     building_type:,
                                                     auto_zone: true
  )

    test_dir = "#{File.dirname(__FILE__)}/output"
    if !Dir.exists?(test_dir)
      Dir.mkdir(test_dir)
    end

    standard = Standard.build("#{template}")

    if @test_file.nil?
      model_name = "#{building_type}-#{template}-#{File.basename(epw_file, '.epw')}"
      run_dir = "#{test_dir}/#{model_name}"
      if !Dir.exists?(run_dir)
        Dir.mkdir(run_dir)
      end
      #create standard model
      model = standard.model_create_prototype_model(epw_file: epw_file,
                                                    sizing_run_dir: run_dir,
                                                    template: template,
                                                    building_type: building_type,
                                                    new_auto_zoner: auto_zone)
    elsif !@test_output.nil?
      model_name = @test_file
      top_dir_element = /btap_costing/ =~ File.expand_path(File.dirname( __FILE__))
      top_dir_name = File.expand_path(File.dirname(__FILE__))[0..(top_dir_element - 1)]
      run_dir = top_dir_name + 'btap_costing/' + @test_output
      in_file = top_dir_name + 'btap_costing' + @test_fold + @test_file
      model = BTAP::FileIO.load_osm(in_file)
      BTAP::Environment::WeatherFile.new(epw_file).set_weather_file(model)
    else
      model_name = @test_file
      run_dir = "#{test_dir}/#{model_name[0..-5]}"
      if !Dir.exists?(run_dir)
        Dir.mkdir(run_dir)
      end
      top_dir_element = /btap_costing/ =~ File.expand_path(File.dirname( __FILE__))
      top_dir_name = File.expand_path(File.dirname(__FILE__))[0..(top_dir_element - 1)]
      in_file = top_dir_name + 'btap_costing' + @test_fold + @test_file
      model = BTAP::FileIO.load_osm(in_file)
      BTAP::Environment::WeatherFile.new(epw_file).set_weather_file(model)
    end

    if @test_output.nil?
      #run model
      standard.model_run_simulation_and_log_errors(model, run_dir)
    end

    # mimic the process of running this measure in OS App or PAT
    model_out_path = "#{run_dir}/final.osm"
    workspace_path = "#{run_dir}/run/in.idf"
    sql_path = "#{run_dir}/run/eplusout.sql"
    cost_result_json_path = "#{run_dir}/cost_results.json"

    #create osm file to use mimic PAT/OS server called final
    model.save(model_out_path, true)

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio. Ensure files exist.
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    assert(File.exist?(model_out_path), "Could not find osm at this path:#{model_out_path}")
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path))
    assert(File.exist?(workspace_path), "Could not find idf at this path:#{workspace_path}")
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path))
    assert(File.exist?(sql_path), "Could not find sql at this path:#{sql_path}")
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path))


    model.save(model_out_path, true)

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      # create an instance of the measure and runner
      measure = BTAPResults.new
      arguments = measure.arguments()
      argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
      assert_equal(2, arguments.size)
      hourly_data = arguments[0].clone
      assert(hourly_data.setValue("false"))
      argument_map['generate_hourly_report'] = hourly_data
      output_diet = arguments[1].clone
      #hardcode this to false for now.
      assert(output_diet.setValue(false))
      argument_map['output_diet'] = output_diet
      Dir.chdir(run_dir)
      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end
    assert(File.exist?(cost_result_json_path), "Could not find costing json at this path:#{cost_result_json_path}")
    regression_files_folder = "#{File.dirname(__FILE__)}/regression_files"
    expected_result_filename = "#{regression_files_folder}/#{model_name}_expected_result.cost.json"
    test_result_filename = "#{regression_files_folder}/#{model_name}_test_result.cost.json"
    FileUtils.rm(test_result_filename) if File.exists?(test_result_filename)
    if File.exists?(expected_result_filename)
      unless FileUtils.compare_file(cost_result_json_path, expected_result_filename)
        FileUtils.cp(cost_result_json_path, test_result_filename)
        assert(false, "Regression test for #{model_name} produces differences. Examine expected and test result differences in the #{File.dirname(__FILE__)}/regression_files folder ")
      end
    else
      puts "No expected test file...Generating expected file #{expected_result_filename}. Please verify."
      FileUtils.cp(cost_result_json_path, expected_result_filename)
    end
    puts "Regression test for #{model_name} passed."
  end
end


