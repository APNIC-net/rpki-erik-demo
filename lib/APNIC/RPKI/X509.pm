package APNIC::RPKI::X509;

use warnings;
use strict;

use Convert::ASN1;

use constant X509_ASN1 => q(
Attribute ::= SEQUENCE {
        type                    AttributeType,
        values                  SET OF AttributeValue
                -- at least one value is required --
        }

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= ANY

AttributeTypeAndValue ::= SEQUENCE {
        type                    AttributeType,
        value                   AttributeValue
        }


Name ::= CHOICE { -- only one possibility for now
        rdnSequence             RDNSequence
        }

RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

DistinguishedName ::= RDNSequence

RelativeDistinguishedName ::=
        SET OF AttributeTypeAndValue  --SET SIZE (1 .. MAX) OF


DirectoryString ::= CHOICE {
        teletexString           TeletexString,  --(SIZE (1..MAX)),
        printableString         PrintableString,  --(SIZE (1..MAX)),
        bmpString               BMPString,  --(SIZE (1..MAX)),
        universalString         UniversalString,  --(SIZE (1..MAX)),
        utf8String              UTF8String,  --(SIZE (1..MAX)),
        ia5String               IA5String,  --added for EmailAddress,
        integer                 INTEGER
        }


Certificate ::= SEQUENCE  {
        tbsCertificate          TBSCertificate,
        signatureAlgorithm      AlgorithmIdentifier,
        signature               BIT STRING
        }

TBSCertificate  ::=  SEQUENCE  {
        version             [0] EXPLICIT Version OPTIONAL,  --DEFAULT v1
        serialNumber            CertificateSerialNumber,
        signature               AlgorithmIdentifier,
        issuer                  Name,
        validity                Validity,
        subject                 Name,
        subjectPublicKeyInfo    SubjectPublicKeyInfo,
        issuerUniqueID      [1] IMPLICIT UniqueIdentifier OPTIONAL,
                -- If present, version shall be v2 or v3
        subjectUniqueID     [2] IMPLICIT UniqueIdentifier OPTIONAL,
                -- If present, version shall be v2 or v3
        extensions          [3] EXPLICIT Extensions OPTIONAL
                -- If present, version shall be v3
        }

Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

CertificateSerialNumber ::= INTEGER

Validity ::= SEQUENCE {
        notBefore               Time,
        notAfter                Time
        }

Time ::= CHOICE {
        utcTime                 UTCTime,
        generalTime             GeneralizedTime
        }

UniqueIdentifier ::= BIT STRING

SubjectPublicKeyInfo ::= SEQUENCE {
        algorithm               AlgorithmIdentifier,
        subjectPublicKey        BIT STRING
        }

Extensions ::= SEQUENCE OF Extension  --SIZE (1..MAX) OF Extension

Extension ::= SEQUENCE {
        extnID                  OBJECT IDENTIFIER,
        critical                BOOLEAN OPTIONAL,  --DEFAULT FALSE,
        extnValue               OCTET STRING
        }

AlgorithmIdentifier ::= SEQUENCE {
        algorithm               OBJECT IDENTIFIER,
        parameters              ANY OPTIONAL
        }


--extensions

AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] KeyIdentifier            OPTIONAL,
      authorityCertIssuer       [1] GeneralNames             OPTIONAL,
      authorityCertSerialNumber [2] CertificateSerialNumber  OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

KeyIdentifier ::= OCTET STRING

-- id-ce-keyUsage OBJECT IDENTIFIER ::=  { id-ce 14 }

SubjectKeyIdentifier ::= KeyIdentifier

-- key usage extension OID and syntax

-- id-ce-keyUsage OBJECT IDENTIFIER ::=  { id-ce 15 }

KeyUsage ::= BIT STRING --{
--      digitalSignature        (0),
--      nonRepudiation          (1),
--      keyEncipherment         (2),
--      dataEncipherment        (3),
--      keyAgreement            (4),
--      keyCertSign             (5),
--      cRLSign                 (6),
--      encipherOnly            (7),
--      decipherOnly            (8) }


-- private key usage period extension OID and syntax

-- id-ce-privateKeyUsagePeriod OBJECT IDENTIFIER ::=  { id-ce 16 }

PrivateKeyUsagePeriod ::= SEQUENCE {
     notBefore       [0]     GeneralizedTime OPTIONAL,
     notAfter        [1]     GeneralizedTime OPTIONAL }
     -- either notBefore or notAfter shall be present

-- certificate policies extension OID and syntax
-- id-ce-certificatePolicies OBJECT IDENTIFIER ::=  { id-ce 32 }

CertificatePolicies ::= SEQUENCE OF PolicyInformation

PolicyInformation ::= SEQUENCE {
     policyIdentifier   CertPolicyId,
     policyQualifiers   SEQUENCE OF
             PolicyQualifierInfo OPTIONAL }

CertPolicyId ::= OBJECT IDENTIFIER

PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId  PolicyQualifierId,
       qualifier        ANY } --DEFINED BY policyQualifierId }

-- Implementations that recognize additional policy qualifiers shall
-- augment the following definition for PolicyQualifierId

PolicyQualifierId ::=
     OBJECT IDENTIFIER --( id-qt-cps | id-qt-unotice )

Qualifier ::= CHOICE {
         cPSuri           CPSuri,
         userNotice       UserNotice }

-- CPS pointer qualifier

CPSuri ::= IA5String

-- user notice qualifier

UserNotice ::= SEQUENCE {
     noticeRef        NoticeReference OPTIONAL,
     explicitText     DisplayText OPTIONAL}

NoticeReference ::= SEQUENCE {
     organization     DisplayText,
     noticeNumbers    SEQUENCE OF INTEGER }

DisplayText ::= CHOICE {
     ia5String        IA5String,
     visibleString    VisibleString  ,
     bmpString        BMPString      ,
     utf8String       UTF8String      }


-- policy mapping extension OID and syntax
-- id-ce-policyMappings OBJECT IDENTIFIER ::=  { id-ce 33 }

PolicyMappings ::= SEQUENCE OF SEQUENCE {
     issuerDomainPolicy      CertPolicyId,
     subjectDomainPolicy     CertPolicyId }


-- subject alternative name extension OID and syntax
-- id-ce-subjectAltName OBJECT IDENTIFIER ::=  { id-ce 17 }

SubjectAltName ::= GeneralNames

GeneralNames ::= SEQUENCE OF GeneralName

GeneralName ::= CHOICE {
     otherName                       [0]     AnotherName,
     rfc822Name                      [1]     IA5String,
     dNSName                         [2]     IA5String,
     x400Address                     [3]     ORAddress,
     directoryName                   [4]     Name,
     ediPartyName                    [5]     EDIPartyName,
     uniformResourceIdentifier       [6]     IA5String,
     iPAddress                       [7]     OCTET STRING,
     registeredID                    [8]     OBJECT IDENTIFIER }

-- ORAddress is adapted from
-- https://www.itu.int/wftp3/Public/t/fl/ietf/rfc/rfc3280/PKIX1Explicit88.html
-- so as to work with Convert::ASN1. 
--
-- The only certificate found in the wild that uses ORAddress is
-- t/x400-cert.pem, got from
-- https://github.com/kaikramer/keystore-explorer/issues/194.  The
-- ORAddress value there is fairly simple, so there's a reasonable
-- chance that this schema won't work perfectly for other ORAddress
-- values that are found.  See also the comments below regarding
-- ExtensionAttributes

ORAddress ::= SEQUENCE {
    built-in-standard-attributes       BuiltInStandardAttributes,
    built-in-domain-defined-attributes BuiltInDomainDefinedAttributes OPTIONAL,
    extension-attributes               ExtensionAttributes OPTIONAL 
}

BuiltInStandardAttributes ::= SEQUENCE {
    country-name                 CountryName OPTIONAL,
    administration-domain-name   AdministrationDomainName OPTIONAL,
    network-address              [0] IMPLICIT NetworkAddress OPTIONAL,
    terminal-identifier          [1] IMPLICIT TerminalIdentifier OPTIONAL,
    private-domain-name          [2] PrivateDomainName OPTIONAL,
    organization-name            [3] IMPLICIT OrganizationName OPTIONAL,
    numeric-user-identifier      [4] IMPLICIT NumericUserIdentifier OPTIONAL,
    personal-name                [5] IMPLICIT PersonalName OPTIONAL,
    organizational-unit-names    [6] IMPLICIT OrganizationalUnitNames OPTIONAL
}

CountryName ::= [APPLICATION 1] CHOICE {
    x121-dcc-code        NumericString,
    iso-3166-alpha2-code PrintableString
}

AdministrationDomainName ::= [APPLICATION 2] CHOICE {
    numeric   NumericString,
    printable PrintableString 
}

NetworkAddress ::= X121Address  -- see also extended-network-address

X121Address ::= NumericString 

TerminalIdentifier ::= PrintableString 

PrivateDomainName ::= CHOICE {
    numeric NumericString,
    printable PrintableString
}

OrganizationName ::= PrintableString
                             
NumericUserIdentifier ::= NumericString

PersonalName ::= SET {
    surname    [0] IMPLICIT PrintableString,
    given-name [1] IMPLICIT PrintableString OPTIONAL,
    initials   [2] IMPLICIT PrintableString OPTIONAL,
    generation-qualifier [3] IMPLICIT PrintableString OPTIONAL
}

OrganizationalUnitNames ::= SEQUENCE OF OrganizationalUnitName

OrganizationalUnitName ::= PrintableString 

BuiltInDomainDefinedAttributes ::= SEQUENCE OF BuiltInDomainDefinedAttribute

BuiltInDomainDefinedAttribute ::= SEQUENCE {
    type PrintableString,
    value PrintableString
}

ExtensionAttributes ::= SET OF ExtensionAttribute

ExtensionAttribute ::=  SEQUENCE {
    extension-attribute-type  [0] IMPLICIT INTEGER,
    -- This should be "ANY DEFINED BY extension-attribute-type", which
    -- Convert::ASN1 is able to parse, but with that type, some of
    -- the metadata about the type is included as part of the value.
    -- For example, in t/x400-cert.pem, there is a single extension
    -- attribute with the type PrintableString, and with "ANY ..." the
    -- value of that string is 19 (i.e. the PrintableString type), 8
    -- (the length of the string), and then the string proper.
    -- Whereas with "EXPLICIT PrintableString", it parses correctly.
    -- This may be an issue if other extension types are seen (which
    -- is unlikely).
    extension-attribute-value [1] EXPLICIT PrintableString
}

-- Extension types and attribute values

--  common-name INTEGER ::= 1
CommonName ::= PrintableString 

--  teletex-common-name INTEGER ::= 2
TeletexCommonName ::= TeletexString 

--  teletex-organization-name INTEGER ::= 3
TeletexOrganizationName ::= TeletexString 

--  teletex-personal-name INTEGER ::= 4
TeletexPersonalName ::= SET {
    surname    [0] IMPLICIT TeletexString,
    given-name [1] IMPLICIT TeletexString OPTIONAL,
    initials   [2] IMPLICIT TeletexString OPTIONAL,
    generation-qualifier [3] TeletexString OPTIONAL
}

--  teletex-organizational-unit-names INTEGER ::= 5
TeletexOrganizationalUnitNames ::= SEQUENCE OF TeletexOrganizationalUnitName

TeletexOrganizationalUnitName ::= TeletexString
                         
--  pds-name INTEGER ::= 7
PDSName ::= PrintableString 

--  physical-delivery-country-name INTEGER ::= 8
PhysicalDeliveryCountryName ::= CHOICE {
    x121-dcc-code NumericString,
    iso-3166-alpha2-code PrintableString
}

--  postal-code INTEGER ::= 9
PostalCode ::= CHOICE {
    numeric-code NumericString,
    printable-code PrintableString
}

--  physical-delivery-office-name INTEGER ::= 10
PhysicalDeliveryOfficeName ::= PDSParameter

--  physical-delivery-office-number INTEGER ::= 11
PhysicalDeliveryOfficeNumber ::= PDSParameter

--  extension-OR-address-components INTEGER ::= 12
ExtensionORAddressComponents ::= PDSParameter

--  physical-delivery-personal-name INTEGER ::= 13
PhysicalDeliveryPersonalName ::= PDSParameter

--  physical-delivery-organization-name INTEGER ::= 14
PhysicalDeliveryOrganizationName ::= PDSParameter

--  extension-physical-delivery-address-components INTEGER ::= 15
ExtensionPhysicalDeliveryAddressComponents ::= PDSParameter

--  unformatted-postal-address INTEGER ::= 16
UnformattedPostalAddress ::= SET {
    printable-address SEQUENCE OF PrintableString OPTIONAL,
    teletex-string TeletexString OPTIONAL
}

--  street-address INTEGER ::= 17
StreetAddress ::= PDSParameter

--  post-office-box-address INTEGER ::= 18
PostOfficeBoxAddress ::= PDSParameter

--  poste-restante-address INTEGER ::= 19
PosteRestanteAddress ::= PDSParameter

--  unique-postal-name INTEGER ::= 20
UniquePostalName ::= PDSParameter

--  local-postal-attributes INTEGER ::= 21
LocalPostalAttributes ::= PDSParameter

PDSParameter ::= SET {
    printable-string PrintableString OPTIONAL,
    teletex-string TeletexString OPTIONAL
}

--  extended-network-address INTEGER ::= 22
E1634Address ::= SEQUENCE {
    number      [0] IMPLICIT NumericString ,
    sub-address [1] IMPLICIT NumericString OPTIONAL
}
ExtendedNetworkAddress ::= CHOICE {
    e163-4-address E1634Address,
    psap-address [0] IMPLICIT PresentationAddress
}

ExtendedNetworkAddress ::= ANY

PresentationAddress ::= SEQUENCE {
    pSelector       [0] EXPLICIT OCTET STRING OPTIONAL,
    sSelector       [1] EXPLICIT OCTET STRING OPTIONAL,
    tSelector       [2] EXPLICIT OCTET STRING OPTIONAL,
    nAddresses      [3] EXPLICIT SET OF OCTET STRING
}

--  terminal-type  INTEGER ::= 23
-- Unable to be parsed, not that it matters very much.
-- TerminalType ::= INTEGER {
--    telex (3),
--    teletex (4),
--    g3-facsimile (5),
--    g4-facsimile (6),
--    ia5-terminal (7),
--    videotex (8) } 

--      Extension Domain-defined Attributes

--  teletex-domain-defined-attributes INTEGER ::= 6
TeletexDomainDefinedAttributes ::= SEQUENCE OF TeletexDomainDefinedAttribute
TeletexDomainDefinedAttribute ::= SEQUENCE {
    type  TeletexString,
    value TeletexString
}

-- End of ORAddress schema.

EntrustVersionInfo ::= SEQUENCE {
              entrustVers  GeneralString,
              entrustInfoFlags EntrustInfoFlags }

EntrustInfoFlags::= BIT STRING --{
--      keyUpdateAllowed
--      newExtensions     (1),  -- not used
--      pKIXCertificate   (2) } -- certificate created by pkix

-- AnotherName replaces OTHER-NAME ::= TYPE-IDENTIFIER, as
-- TYPE-IDENTIFIER is not supported in the 88 ASN.1 syntax

AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }

EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString }


-- issuer alternative name extension OID and syntax
-- id-ce-issuerAltName OBJECT IDENTIFIER ::=  { id-ce 18 }

IssuerAltName ::= GeneralNames


-- id-ce-subjectDirectoryAttributes OBJECT IDENTIFIER ::=  { id-ce 9 }

SubjectDirectoryAttributes ::= SEQUENCE OF Attribute


-- basic constraints extension OID and syntax
-- id-ce-basicConstraints OBJECT IDENTIFIER ::=  { id-ce 19 }

BasicConstraints ::= SEQUENCE {
     cA                      BOOLEAN OPTIONAL, --DEFAULT FALSE,
     pathLenConstraint       INTEGER OPTIONAL }


-- name constraints extension OID and syntax
-- id-ce-nameConstraints OBJECT IDENTIFIER ::=  { id-ce 30 }

NameConstraints ::= SEQUENCE {
     permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
     excludedSubtrees        [1]     GeneralSubtrees OPTIONAL }

GeneralSubtrees ::= SEQUENCE OF GeneralSubtree

GeneralSubtree ::= SEQUENCE {
     base                    GeneralName,
     minimum         [0]     BaseDistance OPTIONAL, --DEFAULT 0,
     maximum         [1]     BaseDistance OPTIONAL }

BaseDistance ::= INTEGER


-- policy constraints extension OID and syntax
-- id-ce-policyConstraints OBJECT IDENTIFIER ::=  { id-ce 36 }

PolicyConstraints ::= SEQUENCE {
     requireExplicitPolicy           [0] SkipCerts OPTIONAL,
     inhibitPolicyMapping            [1] SkipCerts OPTIONAL }

SkipCerts ::= INTEGER


-- CRL distribution points extension OID and syntax
-- id-ce-cRLDistributionPoints     OBJECT IDENTIFIER  ::=  {id-ce 31}

cRLDistributionPoints  ::= SEQUENCE OF DistributionPoint

DistributionPoint ::= SEQUENCE {
     distributionPoint       [0]     DistributionPointName OPTIONAL,
     reasons                 [1]     ReasonFlags OPTIONAL,
     cRLIssuer               [2]     GeneralNames OPTIONAL }

DistributionPointName ::= CHOICE {
     fullName                [0]     GeneralNames,
     nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }

ReasonFlags ::= BIT STRING --{
--     unused                  (0),
--     keyCompromise           (1),
--     cACompromise            (2),
--     affiliationChanged      (3),
--     superseded              (4),
--     cessationOfOperation    (5),
--     certificateHold         (6),
--     privilegeWithdrawn      (7),
--     aACompromise            (8) }

-- id-ce-issuingDistributionPoint OBJECT IDENTIFIER ::= { id-ce 28 }

IssuingDistributionPoint ::= SEQUENCE {
     distributionPoint          [0] DistributionPointName OPTIONAL,
     onlyContainsUserCerts      [1] BOOLEAN OPTIONAL, -- DEFAULT FALSE,
     onlyContainsCACerts        [2] BOOLEAN OPTIONAL, -- DEFAULT FALSE,
     onlySomeReasons            [3] ReasonFlags OPTIONAL,
     indirectCRL                [4] BOOLEAN OPTIONAL, -- DEFAULT FALSE,
     onlyContainsAttributeCerts [5] BOOLEAN OPTIONAL  -- DEFAULT FALSE
}

-- extended key usage extension OID and syntax
-- id-ce-extKeyUsage OBJECT IDENTIFIER ::= {id-ce 37}

ExtKeyUsageSyntax ::= SEQUENCE OF KeyPurposeId

KeyPurposeId ::= OBJECT IDENTIFIER

-- extended key purpose OIDs
-- id-kp-serverAuth      OBJECT IDENTIFIER ::= { id-kp 1 }
-- id-kp-clientAuth      OBJECT IDENTIFIER ::= { id-kp 2 }
-- id-kp-codeSigning     OBJECT IDENTIFIER ::= { id-kp 3 }
-- id-kp-emailProtection OBJECT IDENTIFIER ::= { id-kp 4 }
-- id-kp-ipsecEndSystem  OBJECT IDENTIFIER ::= { id-kp 5 }
-- id-kp-ipsecTunnel     OBJECT IDENTIFIER ::= { id-kp 6 }
-- id-kp-ipsecUser       OBJECT IDENTIFIER ::= { id-kp 7 }
-- id-kp-timeStamping    OBJECT IDENTIFIER ::= { id-kp 8 }

       IPAddrBlocks        ::= SEQUENCE OF IPAddressFamily

       IPAddressFamily     ::= SEQUENCE { -- AFI & opt SAFI --
          addressFamily        OCTET STRING , -- (SIZE (2..3)), --
          ipAddressChoice      IPAddressChoice }

       IPAddressChoice     ::= CHOICE {
          inherit              NULL, -- inherit from issuer --
          addressesOrRanges    SEQUENCE OF IPAddressOrRange }

       IPAddressOrRange    ::= CHOICE {
          addressPrefix        IPAddress,
          addressRange         IPAddressRange }

       IPAddressRange      ::= SEQUENCE {
          min                  IPAddress,
          max                  IPAddress }

       IPAddress           ::= BIT STRING

       ASIdentifiers       ::= SEQUENCE {
           asnum               [0] ASIdentifierChoice OPTIONAL,
           rdi                 [1] ASIdentifierChoice OPTIONAL }

       ASIdentifierChoice  ::= CHOICE {
          inherit              NULL, -- inherit from issuer --
          asIdsOrRanges        SEQUENCE OF ASIdOrRange }

       ASIdOrRange         ::= CHOICE {
           id                  ASId,
           range               ASRange }

       ASRange             ::= SEQUENCE {
           min                 ASId,
           max                 ASId }

       ASId                ::= INTEGER

-- authority info access

-- id-pe-authorityInfoAccess OBJECT IDENTIFIER ::= { id-pe 1 }

AuthorityInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription

AccessDescription  ::=  SEQUENCE {
        accessMethod          OBJECT IDENTIFIER,
        accessLocation        GeneralName  }

-- subject info access

-- id-pe-subjectInfoAccess OBJECT IDENTIFIER ::= { id-pe 11 }

SubjectInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription


-- id-ad OBJECT IDENTIFIER  ::=  { id-pkix 48 }

-- id-ad-caIssuers OBJECT IDENTIFIER  ::=  { id-ad 2 }

RSAPublicKey ::= SEQUENCE {
    modulus            INTEGER,    -- n
    publicExponent     INTEGER  }  -- e

-- pgp creation time

PGPExtension ::= SEQUENCE {
       version             Version, -- DEFAULT v1(0)
       keyCreation         Time
}

-- CRL structures

CertificateList  ::=  SEQUENCE  {
     tbsCertList          TBSCertList,
     signatureAlgorithm   AlgorithmIdentifier,
     signature            BIT STRING  }

TBSCertList  ::=  SEQUENCE  {
     version                 Version OPTIONAL,
                                  -- if present, MUST be v2
     signature               AlgorithmIdentifier,
     issuer                  Name,
     thisUpdate              Time,
     nextUpdate              Time OPTIONAL,
     revokedCertificates     revokedCertificates OPTIONAL,
     crlExtensions           [0] EXPLICIT Extensions OPTIONAL }
                                         -- if present, MUST be v2

revokedCertificates ::=   SEQUENCE OF revokedCertificate

revokedCertificate ::=  SEQUENCE  {
          userCertificate         CertificateSerialNumber,
          revocationDate          Time,
          crlEntryExtensions      Extensions OPTIONAL
                                         -- if present, MUST be v2
                               }

-- Version, Time, CertificateSerialNumber, and Extensions were
-- defined earlier for use in the certificate structure

-- CRL number extension OID and syntax

-- id-ce-cRLNumber OBJECT IDENTIFIER ::= { id-ce 20 }

CRLNumber ::= INTEGER -- (0..MAX)


-- Requests

CertificationRequestInfo ::= SEQUENCE {
    version          Version,
    subject          Name,
    subjectPublicKeyInfo SubjectPublicKeyInfo,
    attributes       [0] Attributes            OPTIONAL }

-- Attributes ::= SET OF Attribute
Attributes ::= SEQUENCE OF Attribute

CertificationRequest ::= SEQUENCE {
    certificationRequestInfo CertificationRequestInfo,
    signatureAlgorithm       AlgorithmIdentifier,
    signature                BIT STRING
}
);

use base qw(Class::Accessor);
APNIC::RPKI::X509->mk_accessors(qw(
    payload
));

my $parser;

sub new
{
    my ($class) = @_;

    if (not $parser) {
        $parser = Convert::ASN1->new();
        $parser->configure(
            encoding => "DER",
            encode   => { time => "utctime" },
            decode   => { time => "utctime" }
        );
        my $res = $parser->prepare(X509_ASN1());
        if (not $res) {
            die $parser->error();
        }
        $parser = $parser->find('Certificate');
    }

    my $self = { parser => $parser };
    bless $self, $class;
    return $self;
}

sub decode
{
    my ($self, $cert) = @_;

    my $parser = $self->{'parser'};
    my $data = $parser->decode($cert);
    if (not $data) {
        die $parser->error();
    }

    $self->payload($data);
    return 1;
}

1;
