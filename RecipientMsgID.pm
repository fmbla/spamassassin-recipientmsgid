package Mail::SpamAssassin::Plugin::RecipientMsgID;
my $VERSION = 0.22;

use strict;
use Mail::SpamAssassin::Plugin;
use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

sub dbg {
  Mail::SpamAssassin::Plugin::dbg ("RecipientMsgID: @_");
}

sub uri_to_domain {
  my ($self, $domain) = @_;

  if ($Mail::SpamAssassin::VERSION <= 3.004000) {
    Mail::SpamAssassin::Util::uri_to_domain($domain);
  } else {
    $self->{main}->{registryboundaries}->uri_to_domain($domain);
  }
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

  if (defined $message_id) {
    $message_id = $self->uri_to_domain($message_id);
  }

  return 0 if $message_id eq '';
  dbg("Message-Id: $message_id");

  my $from = lc($pms->get("From:addr"));
  my $replyto = lc($pms->get("Reply-To:addr"));
  my $from_dom = '';

  $from_dom = $self->uri_to_domain($from);

  if ($replyto) {
    $from_dom = $self->uri_to_domain($replyto);
  }

  return 0 if $from_dom eq '';

  dbg("FromDom: $from_dom");

  my $matched = 0;

  my @toaddrs;

  for ('ToCc', 'Bcc') {
    my $to = $pms->get($_ . ":addr");     # get recipients
    if ($to) {
      $to = $self->uri_to_domain($to);
      dbg("ToDom: $to");
      push(@toaddrs, $to);
    }
  }

  foreach my $to_domain (@toaddrs) {
    if ($to_domain eq $message_id) {
      $matched = 1;
    }
  }

  if (($from_dom ne $message_id) && ($matched == 1)) {
    dbg("Message ID matches recipient domain");
    return 1;
  }

  return 0;
}

1;
