use jmaptest;

attr pristine => 1;

test {
  my ($self) = @_;

  my $account = $self->pristine_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:submission',
  ) or return;

  my $res = $tester->request([[
    "EmailSubmission/query" => {},
  ]]);
  ok($res->is_success, "EmailSubmission/query") or diag explain $res->response_payload;

  my $args = $res->single_sentence("EmailSubmission/query")->arguments;

  ok(defined $args->{queryState},         "has queryState");
  ok(defined $args->{position},           "has position");
  ok(defined $args->{total},              "has total");
  ok(ref $args->{ids} eq 'ARRAY',         "ids is array");
  # RFC 8620 S5.5: canCalculateChanges is true "if the server supports calling
  # Foo/queryChanges with these filter/sort parameters" -- false is a legal
  # answer, not a failure. Only its presence and type are required.
  ok(defined $args->{canCalculateChanges}, "has canCalculateChanges");
  note("server reports canCalculateChanges false for this query")
    unless $args->{canCalculateChanges};

  is($args->{position}, 0,              "position is 0 for empty list");
  is($args->{total},    0,              "total is 0 for pristine account");
  is(scalar @{ $args->{ids} }, 0,      "no submission ids in pristine account");
};
