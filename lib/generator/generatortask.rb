require 'rake/tasklib'

module FFI
  module Generator
    class Task < Rake::TaskLib
      def initialize(options = {})
        @options = { :input_fn => '*.i', :output_dir => 'generated/' }.merge(options)
        namespace 'ffi' do
          define_generate_task
          define_clean_task
        end
      end
      private
      def define_file_task(fn, xml_fn, output_fn)
        desc "Generate #{output_fn} from #{fn}"
        file output_fn => fn do
          mkdir_p @options[:output_dir], :verbose => false
          puts "Generating #{xml_fn} from #{fn} using SWIG..."
          `swig -xml #{xml_fn} #{fn}`
          puts "Generating #{output_fn} from #{xml_fn}..."
          File.open(output_fn, 'w') do |file|
            file << Parser.generate(Nokogiri::XML(File.open(xml_fn)))
          end
        end
      end
      def define_file_tasks
        Dir.glob(@options[:input_fn]).inject([]) do |output_fns, fn|
          output_fn = File.join(@options[:output_dir], "#{File.basename(fn, '.i')}_wrap.rb")
          xml_fn = File.join(@options[:output_dir], "#{File.basename(fn, '.i')}_wrap.xml")
          define_file_task(fn, xml_fn, output_fn)
          output_fns << output_fn
        end
      end
      def define_generate_task
        (task :generate => define_file_tasks).add_description('Generate all files')
      end
      def define_clean_task
        desc 'Remove all generated files'
        task :clean do
          rm_rf @options[:output_dir] unless @options[:output_dir] == '.'
        end
      end
    end
  end
end