# Enable experimental HAML support with the ERB Dependency Tracker
CacheDigests::DependencyTracker.register_tracker :haml, CacheDigests::DependencyTracker::ERBTracker
