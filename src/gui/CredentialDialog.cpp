#include "CredentialDialog.h"
#include "ui_CredentialDialog.h"

using namespace governikus;

CredentialDialog::CredentialDialog(QWidget* pParent)
	: QDialog(pParent)
	, mUi(new Ui::CredentialDialog)
{
	mUi->setupUi(this);

	setWindowFlags(Qt::Window | Qt::WindowTitleHint | Qt::WindowCloseButtonHint | Qt::WindowSystemMenuHint);
	setWindowTitle(QCoreApplication::applicationName() + " - " + tr("Proxy security"));

	connect(mUi->buttonBox, &QDialogButtonBox::accepted, this, &CredentialDialog::accept);
	connect(mUi->buttonBox, &QDialogButtonBox::rejected, this, &CredentialDialog::reject);
}


CredentialDialog::~CredentialDialog()
{
	delete mUi;
}


void CredentialDialog::setUser(const QString& pUser)
{
	if (!pUser.isEmpty())
	{
		mUi->user->setText(pUser);
		mUi->password->setFocus();
		mUi->password->setCursorPosition(0);
	}
}


QString CredentialDialog::getUser() const
{
	return mUi->user->text();
}


QString CredentialDialog::getPassword() const
{
	return mUi->password->text();
}
