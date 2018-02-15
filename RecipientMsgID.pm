package Mail::SpamAssassin::Plugin::RecipientMsgID;
my $VERSION = 0.1;

use strict;
use Mail::SpamAssassin::Plugin;
use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

sub dbg {
  Mail::SpamAssassin::Plugin::dbg ("RecipientMsgID: @_");
}

sub new {
  my ($class, $mailsa) = @_;

  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsa);
  bless ($self, $class);

  $self->register_eval_rule("check_msgid_belongs_recipient");

  return $self;
}

sub check_msgid_belongs_recipient {
  my ($self, $pms) = @_;

  my $message_id = lc($pms->get("Message-Id"));
  chomp $message_id;
  $message_id =~ s/\>$//;

  if (defined $message_id && $message_id =~ /\@([^@. \t]+\.[^@ \t]+?)[ \t]*\z/s) {
    $message_id = lc $1;
  }
  return 0 if $message_id eq '';

  my $from = lc($pms->get("From:addr"));
  my $replyto = lc($pms->get("Reply-To:addr"));
  my $from_dom = '';

  if (defined $from && $from =~ /\@([^@. \t]+\.[^@ \t]+?)[ \t]*\z/s) {
    $from_dom = $1;
  }

  if (defined $replyto && $replyto =~ /\@([^@. \t]+\.[^@ \t]+?)[ \t]*\z/s) {
    $from_dom = $1;
  }

  return 0 if $from_dom eq '';

  my $matched = 0;

  my @inputs;

  for ('ToCc', 'Bcc') {
    my $to = $pms->get($_);     # get recipients
    $to =~ s/\(.*?\)//g;        # strip out the (comments)
    push(@inputs, ($to =~ m/([\w.=-]+\@\w+(?:[\w.-]+\.)+\w+)/g));
  }

  foreach my $to_addr (@inputs) {
    $to_addr =~ /\@([^@. \t]+\.[^@ \t]+?)[ \t]*\z/s;
    if ($1 eq $message_id) {
      $matched = 1;
    }
  }

  if (($from_dom ne $message_id) && ($matched == 1)) {
    return 1;
  }

  return 0;
}

1;
