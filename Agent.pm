=head1 NAME

Agent - supplies agentspace methods for perl5.

=head1 SYNOPSIS

	use Agent;
   
	$my_agent = new Agent;
  $my_other_agent = new Agent;

	$my_agent->add( Name => 'AgentName',
                 Value => 'Test-Agent' );
	$my_agent->write( Name => 'AgentName'
									 Value => 'Agent-Test' );

  $trs = $my_agent->packself();
  unpackself $my_other_agent Agent => $trs;

  $AgentsName = $my_other_agent->read(Name => 'AgentName');
   
=head1 DESCRIPTION

C<Agent::new> creates C<Agent> objects,  variables can be stored and
retrieved within the C<Agent>'s agentspace with the C<Agent::add>, 
C<Agent::write>, and C<Agent::read> methods.  When the C<Agent> needs to 
be transported,  it can be packed completely via the C<Agent::packself> 
method.  Once it gets wherever it's going,  use C<Agent::unpackself> to 
turn it back into an object.   

=head1 HISTORY

Agent 2.9 was written by James Duncan <jduncan@hawk.igs.net>,  May 23, 1996.
The original Agent (1.0) was written on May 21, 1996.

=cut

package Agent;

$VERSION = '2.9';

# create a new agentspace object.
sub new {
  my ($class, %args) = @_;
  my $self = {};
  $self->{'Scope'} = 'Agent $VERSION';
  bless $self, $class;
}


# add variables into the agentspace.
sub add {
  my ($self, %args) = @_;
  if(!(length($self->{'Vars'}) == 0)) {
    $self->{'Vars'} = $self->{'Vars'} . "," . $args{'Name'} . "," . $args{'Value'};
  } else { 
    $self->{'Vars'} = $args{'Name'} . "," . $args{'Value'};
  }
 return;
}

# modify variables within the agentspace.
sub write {
  my ($self, %args) = @_;

  # Perhaps I'll fix this someday.. until then,  it's a hack.
  # $self->{'Vars'} =~ s/$args{'Name'},.,/$args{'Name'},$args{'Value'},/;
  
  @vars = split(/,/,$self->{'Vars'});
  $county = 0;
  foreach $var (@vars) {
    if($var eq $args{'Name'}) {
      $locator = $county+1;
    }
   $county++;
  }
  if($locator) { $vars[$locator] = $args{'Value'} }
  $self->{'Vars'} = join(',',@vars);
  chop($self);
  return;
} 

# read variables from within the agentspace.
sub read {
  my ($self, %args) = @_;
  my $mod = $self->{'Vars'};
  @vars = split(/,/, $mod);
  $count = 0;
  foreach $one (@vars) {
    if ($one eq $args{'Name'}) {
      $locater = $count+1;
    }
  $count++;
  }
return $vars[$locater];
}

# pack the agentspace and return it,  possibly for transportation.
sub packself {
   my ($self, %args) = @_;
   my $time = time;
   my $len = length($self->{'Vars'});
   my $deadagent = 
   "-- Packed Agent V.$VERSION Time: $time $len --\n" . 
   pack("u", $self->{'Vars'} . " |=| " . $self->{'Scope'}) .
   "== Packed Agent V.$VERSION Time: $time $len ==\n";
  return $deadagent;
}

# unpack the agentspace.
sub unpackself {
   my ($self, %args) = @_;
   my @myself = split(/^/,$args{'Agent'});
   my @tprot = split(/ /, shift (@myself));
   my @bprot = split(/ /, pop (@myself));
   my $text = join('', @myself) || print "Packing Error: Empty Agent.";
   my @types = split(/\|\=\|/,unpack("u",$text));
   $self->{'Vars'} = $types[0];
   $self->{'Scope'} = $types[1];
}
	
# list the contents of the agentspace.
sub contents {
   my ($self, %args) = @_;
   return $self->{'Vars'};
}

1;