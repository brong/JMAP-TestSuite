use jmaptest;

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  # Get us a mailbox to play with
  my $batch = $account->create_batch(mailbox => {
    x => { name => "Folder X at $^T.$$" },
  });

  batch_ok($batch);

  ok( $batch->is_entirely_successful, "created a mailbox");
  my $x = $batch->result_for('x');

  my $blob = $account->email_blob(generic => {});
  ok($blob->is_success, "our upload succeeded (" . $blob->blobId . ")");

  $batch = $account->import_messages({
    msg => { blobId => $blob, mailboxIds => { $x->id => \1 }, },
  });

  batch_ok($batch);

  ok($batch->is_entirely_successful, "we uploaded and imported messages");

  subtest "getMessages" => sub {
    my $res = $tester->request([[
      'Email/get' => {
        ids => [ $batch->result_for('msg')->id ],
        properties => [ qw(preview bodyValues textBody) ],
        fetchTextBodyValues => JSON::true,
      },
    ]]);

    my $email = $res->single_sentence->arguments->{list}[0];

    my $text_id = $email->{textBody}[0]{partId};
    my $text_body = $email->{bodyValues}{$text_id}{value};

    is(
      $text_body,
      'This is a very simple message.',
      'text body is correct'
    ) or diag explain $email;

    # RFC 8621 S4.1 constrains "preview" only by "MUST NOT be more than 256
    # characters"; the server "may choose which part of the message to
    # include", and may collapse whitespace or skip salutations. So the shape
    # is asserted, not the content -- requiring it to start at the beginning
    # of the body would fail a server exercising the latitude it is given.
    ok(defined $email->{preview}, 'preview is present');
    cmp_ok(length($email->{preview} // ''), '<=', 256, 'preview is not over-long');

    if (length($email->{preview} // '')) {
      note("preview: $email->{preview}");
    }
    else {
      note('server returned an empty preview for a message with a text body');
    }
  };

  subtest "getMessageList" => sub {
    my $res = $tester->request([
      [
        'Email/query' => {
          filter => { inMailbox => $x->id },
        }, 'query',
      ],
      [
        'Email/get' => {
          '#ids' => {
            resultOf => 'query',
            name     => 'Email/query',
            path     => '/ids',
          },
          properties => [ qw(preview bodyValues textBody) ],
          fetchTextBodyValues => JSON::true,
        },
      ],
    ]);

    my $email = $res->sentence(1)->arguments->{list}[0];

    my $text_id = $email->{textBody}[0]{partId};
    my $text_body = $email->{bodyValues}{$text_id}{value};

    is(
      $text_body,
      'This is a very simple message.',
      'text body is correct'
    );

    # RFC 8621 S4.1 constrains "preview" only by "MUST NOT be more than 256
    # characters"; the server "may choose which part of the message to
    # include", and may collapse whitespace or skip salutations. So the shape
    # is asserted, not the content -- requiring it to start at the beginning
    # of the body would fail a server exercising the latitude it is given.
    ok(defined $email->{preview}, 'preview is present');
    cmp_ok(length($email->{preview} // ''), '<=', 256, 'preview is not over-long');

    if (length($email->{preview} // '')) {
      note("preview: $email->{preview}");
    }
    else {
      note('server returned an empty preview for a message with a text body');
    }
  };
};
