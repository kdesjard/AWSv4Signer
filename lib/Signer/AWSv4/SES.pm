package Signer::AWSv4::SES;
  use Moo;
  extends 'Signer::AWSv4';
  use Types::Standard qw/Str/;

  use JSON::MaybeXS qw//;
  use MIME::Base64 qw//;

  has '+expires' => (default => 0);
  #has '+region' => (default => 'us-east-1');
  has '+service' => (default => 'ses');
  has '+method' => (default => '');
  has '+uri' => (default => '/');
  has '+date' => (default => '11111111');

  has smtp_user => (is => 'ro', isa => Str, default => sub {
    my $self = shift;
    return $self->access_key;    
  });
  has smtp_password => (is => 'ro', isa => Str, lazy => 1, builder => '_build_password_v4');
  has smtp_password_v2 => (is => 'ro', isa => Str, lazy => 1, '_build_password_v2');

  has smtp_endpoint => (is => 'ro', isa => Str, default => sub {
    my $self = shift;
    sprintf 'email-smtp.%s.amazonaws.com', $self->region;
  });

  has '+signing_key' => (default => sub {
    my $self = shift;
    my $signature = Digest::SHA::hmac_sha256($self->date, "AWS4" . $self->secret_key);
    $signature = Digest::SHA::hmac_sha256($self->region, $signature);
    $signature = Digest::SHA::hmac_sha256($self->service, $signature);
    $signature = Digest::SHA::hmac_sha256('aws4_request', $signature);
    $signature = Digest::SHA::hmac_sha256('SendRawEmail', $signature);
    return $signature;
  });

  sub _build_password_v2 {
     my $self = shift;
 
    my $signature = Digest::SHA::hmac_sha256('SendRawEmail', $self->secret_key);
    MIME::Base64::encode_base64("\x02" . $signature);
  });

  sub _build_password_v4 {
    my $self = shift;

    my $version = "\x04";
    MIME::Base64::encode_base64($version . $self->signing_key, '');
  }

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Signer::AWSv4::SES - Generate passwords for sending email through SES SMTP servers with IAM credentials

=head1 SYNOPSIS

  use Signer::AWSv4::SES;
  $pass_gen = Signer::AWSv4::SES->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  );
  $pass_gen->smtp_password;

=head1 DESCRIPTION

Generate passwords for sending email through SES SMTP servers with IAM credentials.
The IAM user needs to have the ses:SendRawEmail IAM permission to be able to send mail.

This module generates v4 signatures for SES, unlike lots of other examples around the 
Internet, that use the old v2 signature scheme, although a fallback for obtaining a v2
password is still there, just in case you want to use it.

=head1 Request Attributes

This module needs only two required attributes in the constructor for obtaining a password:

=head2 access_key String

The AWS IAM Access Key for the IAM user

=head2 user String

The user of the MySQL database

=head2 port Integer

The port the database is running on. Defaults to 3306.

=head1 Signature Attributes

=head2 signed_qstring

This has to be used as the password for the MySQL Server. Please note that all of this needs
extra setup: correctly configuring your AWS environment AND your MySQL Client.

=head1 SEE ALSO

L<https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/AWSv4Signer>

Please report bugs to: L<https://github.com/pplu/AWSv4Signer/issues>

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
