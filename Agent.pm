#

=head1 NAME

Agent - supplies agentspace methods for perl5.

=head1 SYNOPSIS

	use Agent;
   

=head1 DESCRIPTION

C<Agent::new> creates C<Agent> objects,  variables can be stored and
retrieved within the C<Agent>'s agentspace with the C<Agent::add>, 
C<Agent::write>, and C<Agent::read> methods.  When the C<Agent> needs to 
be transported,  it can be packed completely via the C<Agent::sleep> 
method.  Once it gets wherever it's going,  use C<Agent::wake> to 
turn it back into an object.  To set the importance (priority level) of the
agentspace,  use the C<Agent::setpriority> method.  You can set the level of
priority to three different values:  C<Urgent>,  C<Normal>,  and C<Low>.
This will eventully define how much precedence the agentspace will have on a
remote machine,  if lots of other agents are also running.  The
C<Agent::addcode> method allows you to add some form of code to the agent. 
It does not matter what language the code is written in,  except when a remote 
machine runs it, the particular remote machine must be able to read and 
parse that language.

Agent 2.91 C<should> be backwardly compatible with the first release of
Agent,  even though Agentspace has had data compartments replaced and added.


=head1 C<Agent::new>

  $my_agent = new Agent;

  Agent::new creates Agentspace objects.


=head1 C<Agent::add>

  $my_agent->add ( Name => 'A_Variable',  Value => 'Untyped_value' );  

  Agent::add allows you to declare new variables inside the Agentspace.


=head1 C<Agent::write>

  $my_agent->write ( Name => 'An_Existing_Variable', Value => 'New_Value' );

  Agent::write lets you re-write (Modify) existing Agentspace variables.


=head1 C<Agent::read>

  $my_value = $my_agent->read ( Name => 'A Variable' );
  
  Agent::read lets you read variables out of the Agentspace.


=head1 C<Agent::addcode>

 $my_agent->addcode ( Code => 'any_code' );

  Agent::addcode lets you add information into the Codespace of the Agent.


=head1 C<Agent::setpriority>

  $my_agent->setpriority ( Level => 'Normal' );

  Agent::setpriority allows you to set the execution priority level of the
Agentspace agent.  It has three levels: C<Urgent>, C<Normal>,  and C<Low>. 
All agents start with priority level set at normal. 


=head1 C<Agent::sleep>

  $my_var = $my_agent->sleep();

  Agent::sleep returns a packed agentspace variable.  The contents of
this variable could then be transported in many ways.
  

=head1 C<Agent::wake>

  wake $my_agent Agent => $sleeping_agent;

  Agent::wake is used to unpack agentspace created with packself.


=head1 C<Agent::contents>

  $my_agent_vars = $my_agent->var_contents();
  $my_agent_code = $my_agent->code_contents();
  $my_agent_level = $my_agent->getlevel();

  Agent::contents returns the contents of the various compartments within
the agentspace.


=head1 HISTORY

Agent 1.0   	General idea and bad implementation. C<Undistibuted!>
Agent 2.0	Better implementation.	C<Undistributed!>
Agent 2.9	Decent implementation. C<First Distribtion!>
Agent 2.91	Decent implementation, works with
                Agentspace2 compartments. C<Distributed>


=head1 AUTHOR

  Agent/Agentspace code written by James Duncan <jduncan@hawk.igs.net>


=head1 CREDITS

  Thanks go out to Steve Purkis <spurkis@hawk.igs.net> and everyone who
has submitted oo modules to CPAN.
 


=cut

#-----------------------------------------------------------------------------
# Agent.pm: Object methods to access agentspace for perl.
# Copyright 1996 James Duncan
# See the file: README for specific details involving the license.
# Version: 2.91
#-----------------------------------------------------------------------------

package Agent;

$VERSION = '2.91';

# create a new agentspace object.
sub new {
  my ($class, %args) = @_;
  my $self = {};
  $self->{'Priority'} = '5';  # set agentspace as normal priority.
  $self->{'Code'} = ''; # make sure the code compartment is clear.
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
  my @vars = split(/,/,$self->{'Vars'});
  my $count = 0;
  foreach $var (@vars) {
    if($var eq $args{'Name'}) {
      $locator = $count;
    }
   $count++;
  }
  if($locator) { 
    $vars[$locator] = $args{'Value'} 
  } else {
    print "Agentspace error: no variable $args{'Name'}\n";
    exit;
  }
  # dirty hack to put commas in after everything.
  $self->{'Vars'} = join(',',@vars);
  # really dirty hack to make sure the last value doesn't have a trailing
  # comma.
  chop($self);
  return;
} 

# read variables from within the agentspace.
sub read {
  my ($self, %args) = @_;
  my $mod = $self->{'Vars'};
  my @vars = split(/,/, $mod);
  my $count = 0;
  # should use split and join for this.
  foreach $one (@vars) {
    if ($one eq $args{'Name'}) {
      $locater = $count+1;
    }
  $count++;
  }
return $vars[$locater];
}

# pack the agentspace and return it,  possibly for transportation.
sub sleep {
   my ($self, %args) = @_;
   my $time = time;
   my $len = length($self->{'Vars'});
   my $deadagent = 
   "-- Packed Agent V.$VERSION $time $len --\n" . 
   pack("u", $self->{'Vars'} . 
   " |=| " . 
   $self->{'Priority'} . 
   " |=| " . $self->{'Code'}) .
   "== Packed Agent V.$VERSION $time $len ==\n";
  return $deadagent;
}

# unpack the agentspace.
sub wake {
   my ($self, %args) = @_;
   my @myself = split(/^/,$args{'Agent'});
   # get the top and bottom Agentspace protocol lines.
   my @tprot = split(/ /, shift (@myself));
   my @bprot = split(/ /, pop (@myself));
   # make v2point9 true if they are using it.
   if ($tprot[4] =~ /\bV.2.9\b/) {
     my $v2point9 = 1;
   }
   my $text = join('', @myself) || print "Packing Error: Empty Agent.";
   my @types = split(/\|\=\|/,unpack("u",$text));
   $self->{'Vars'} = $types[0];
   # don't get the priority and code compartments if
   # they are 4 days behind development and are using v2.9 instead of 2.91
   $self->{'Priority'} = $types[1] unless $v2point9;
   $self->{'Code'} = $types[2] unless $v2point9;
}

# set the agentspace's priority rating
sub setpriority {
   my ($self, %args) = @_;
   if ($args{'Level'} eq 'Normal') { $self->{'Priority'} = 5; }
   elsif ($args{'Level'} eq 'Urgent') { $self->{'Priority'} = 2; }
   elsif ($args{'Level'} eq 'Low') { $self->{'Priority'} = 10; }
   return;
}

# run code from the agentspace
sub execute {
  # this will execute code within a safe namespace and modify the Agent
  # values.  It is here as a placeholder only.  Implementation time
  # is not definite.
}

# add code to the agentspace
sub addcode {
  my ($self, %args) = @_;
  $self->{'Code'} = $args{'Code'};
  return;
}

# list the contents of the various compartments.

sub var_contents {
   my ($self, %args) = @_;
   return $self->{'Vars'};
}

sub code_contents {
   my ($self, %args) = @_;
   return $self->{'Code'};
}

sub getlevel {
   my ($self, %args) = @_;
   return $self->{'Priority'};
}

1;