#!/usr/bin/perl -w

use utf8;
use strict;
use warnings;
use Getopt::Long;

# Install required modules with CPAN
use LWP::UserAgent;
use JSON::PP qw(decode_json encode_json);
use Net::MQTT::Simple;

# Parse command-line arguments
GetOptions(
	"config:s"  => \(my $config = "config.txt")
) or die "Options missing $!";

# Load configuration data from file into shared space
my %config;
open(INFILE, "<:encoding(UTF-8)", $config ) or die "Could not open ${config} $!";
while (<INFILE>) {
	chomp $_;
	my($key, $data) = split(/\t+/, $_);
	$config{$key} = $data;
}

# Create MQTT client
$ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;
my $mqtt = Net::MQTT::Simple->new($config{"mqtthost"});
$mqtt->last_will($config{"topic"} . "/" . "lwt", "Homewizard-P1-MQTT");
$mqtt->login($config{"username"}, $config{"password"});
# Create HTTP user agent
my $ua = LWP::UserAgent->new;

# Configuration
my $homewizard_url = "http://" . $config{"homewizard"} . "/api/v1/data"; # Modified endpoint

my %previous_data;

# Make request to HomeWizard API
sub fetch_data {
	my $response = $ua->get($homewizard_url);
	die "Error fetching data from HomeWizard API" unless $response->is_success;
	return decode_json($response->content);
}

# Publish JSON data to MQTT topic
sub publish_data {
	my ($data, $interval_data) = @_;
	my %combined_data = (%$data, %$interval_data);
	$mqtt->publish($config{topic}, encode_json(\%combined_data));
}

# Calculate interval power consumption
sub calculate_interval_power {
	my ($data, $key) = @_;
	my $interval_key = $key;
	$interval_key =~ s/^total_/interval_/;
	$interval_key =~ s/_kwh$/_w/;
	my $interval_power = 0;
	if (exists $previous_data{$key}) {
		$interval_power = $data->{$key} - $previous_data{$key};
	}
	return ($interval_key, $interval_power);
}

# Main loop
while (1) {
	my $data = fetch_data();
	my %interval_data;

	# Calculate interval power consumption for each attribute
	for my $key (keys %$data) {
	  next unless $key =~ /^total_/;
	  my ($interval_key, $interval_power) = calculate_interval_power($data, $key);
	  if ($interval_power != 0) {
		  $interval_data{$interval_key} = sprintf("%.4f", $interval_power) + 0;
	  }
	  $previous_data{$key} = $data->{$key}; # Update previous data with current data
	}

	# Publish data and interval data to MQTT topic
	publish_data($data, \%interval_data);

	sleep $config{interval};
}

# Close MQTT connection (never reached in this script)
$mqtt->disconnect;
