#!/usr/bin/ruby

# Read the dependencies.yml from the subdirectories in $0,
# and print them out in the order in which they need to be
# built.
# Subdirectories that don't include a dependencies.yaml file
# are listed at the end, in undefined order.
# 
# If successful, exit with 0 and prints the semicolon-separated
# list of subdirectories on stdout.
# In case of failure, exit with a non-zero exit code, and print
# error message to stderr.
# Errors might be a malformed dependencies.yaml file, or a
# missing dependency.

require "yaml"

$NO_DEPENDS = [] # projects with no dependencies
$DEPENDS = [] # projects with dependencies, ordered
$REQUIRED = {} # projects (key) required by other projects (value)

# Add the dependencies from project
def LoadDependencies(project, dependencies)
    pindex = $DEPENDS.index(project)

    # project hasn't been seen yet, append it
    if pindex.nil?
        pindex = $DEPENDS.length
        $DEPENDS.append(project)
    end

    dependencies.each do |dependency, data|
        # dependencies are specified with relative path to this project
        dependency = dependency.gsub("../", "")

        # the dependency is not optional for the project
        if data["required"]
            $REQUIRED[dependency] = [] if $REQUIRED[dependency].nil?
            $REQUIRED[dependency].append(project)
        end

        dindex = $DEPENDS.index(dependency)
        if dindex.nil?
            # the dependency hasn't been seen yet - load it
            $DEPENDS.insert(pindex, dependency)
            LoadProject(dependency)
        elsif dindex > pindex
            # otherwise, make sure it comes before project
            $DEPENDS.insert(pindex, $DEPENDS.delete_at(dindex))
        end
    end
end

# Load the dependencies.yaml file for project and populate $DEPENDS
def LoadProject(project)
    if File.exist?("./#{project}/dependencies.yaml")
        dependencies = YAML.load_file("./#{project}/dependencies.yaml")
        if !dependencies.is_a?(Hash) || dependencies["dependencies"].nil?
            STDERR.puts("Malformed #{project}/dependencies.yaml!")
            exit(1)
        end
        LoadDependencies(project, dependencies["dependencies"])
    else
        $NO_DEPENDS << project
    end
end

def CheckMissingDependencies()
    dependency_missing = false
    $REQUIRED.each do |key, value|
        unless Dir.exist?(key)
            STDERR.puts("Required dependency not available: #{key} needed by #{value}")
            # exit only once we have listed all missing dependencies
            dependency_missing = true
        end
    end
    exit(3) if dependency_missing
end

def LoadProjects(projects)
    projects.each do |project|
        next unless Dir.exist?(project)
        LoadProject(project)
    end

    CheckMissingDependencies()

    $DEPENDS << $NO_DEPENDS unless $NO_DEPENDS.empty?
    STDOUT.puts($DEPENDS.join(";"))
end

LoadProjects(ARGV[0].split(";"))
