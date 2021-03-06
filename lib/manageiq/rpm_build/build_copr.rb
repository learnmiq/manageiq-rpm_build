require 'awesome_spawn'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class BuildCopr
      attr_reader :release_name, :rpm_name, :rpm_release, :rpm_repo_name

      def initialize(name, release_name)
        @rpm_name     = name
        @release_name = release_name

        options        = YAML.load_file(CONFIG_DIR.join("options.yml"))
        rpm_options    = options["rpm"]
        @rpm_release   = rpm_options["release"]
        @rpm_repo_name = rpm_options["repo_name"]
      end

      def generate_rpm
        puts "\n---> #{self.class.name}::#{__method__}"

        Dir.chdir(RPM_SPEC_DIR.join(rpm_name)) do
          update_spec
          #TODO - need to allow customization
          exit $?.exitstatus unless system("rpmbuild -bs --define '_sourcedir .' --define '_srcrpmdir .' #{rpm_name}.spec")
          exit $?.exitstatus unless system("copr-cli --config /build_scripts/copr-cli-token build -r epel-8-x86_64 #{rpm_repo_name} #{rpm_name}-*.src.rpm")
        end
      end

      private

      def update_spec
        puts "\n---> #{self.class.name}::#{__method__}"

        spec_file = "#{rpm_name}.spec"
        spec_text = File.read(spec_file)

        spec_text.sub!("RPM_VERSION", VERSION)
        spec_text.sub!("RPM_RELEASE", spec_release)
        File.write(spec_file, spec_text)
      end

      def spec_release
        if release_name.empty?
          "#{rpm_release}.#{BUILD_DATE}"
        else
          pre_build = release_name.split("-")[2]
          pre_build ? "#{rpm_release}.#{pre_build}" : "#{rpm_release}"
        end
      end
    end
  end
end
